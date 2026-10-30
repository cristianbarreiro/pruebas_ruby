# Caso de Estudio 03: Mesa de Ayuda y Sistema de Tickets (`03_helpdesk_ticketing`)

## Problema

En muchos equipos de soporte técnico los tickets cambian de estado de forma arbitraria (por ejemplo, pasando directamente de `:open` a `:resolved` sin haber sido tomados por ningún técnico, o permaneciendo cerrados sin registrar cuánto tardó su resolución ni el historial de cambios).

Este caso de estudio implementa un motor de mesa de ayuda con máquina de estados explícita (`TransitionPolicy`), trazabilidad completa de transiciones y cálculo de métricas operativas.

## Diseño y Arquitectura

El sistema está dividido en componentes cohesivos con responsabilidades bien delimitadas:

- **Política de Transición (`TransitionPolicy`)**:
  - Gobierna las transiciones válidas de forma independiente a la entidad `Ticket`:
    - `:open -> [:in_progress]`
    - `:in_progress -> [:pending, :resolved]`
    - `:pending -> [:in_progress, :resolved]`
    - `:resolved -> [:open]` (reapertura)
  - Lanza `Errors::InvalidTransitionError` ante cualquier transición no permitida.
- **Entidad de Dominio (`Ticket`)**:
  - Valida campos obligatorios (`id`, `title`, `description`, `requester`, `category`) y prioridades permitidas (`:low`, `:medium`, `:high`, `:critical`).
  - Registra cada cambio de estado en `history` con marcas de tiempo ISO-8601 (`from`, `to`, `at`, `note`).
  - Calcula `resolution_seconds` automáticamente cuando el ticket alcanza el estado `:resolved`, y limpia `resolved_at` si el ticket se reabre (`:resolved -> :open`).
- **Servicio de Aplicación (`TicketService`)**:
  - Gestiona creación con numeración secuencial (`TCK-001`, `TCK-002`, ...), asignación a técnicos, transiciones de estado, búsqueda combinada (`status`, `priority`, `assignee`, `query`) y estadísticas (`stats`).
- **Persistencia e Interfaz (`JsonRepository`, `CLI`)**:
  - `JsonRepository` guarda los tickets y su historial mediante escritura atómica (`.tmp` + `File.rename`).
  - `CLI` permite inyectar los flujos `out:` y `err:` para pruebas deterministas.

```text
case_studies/03_helpdesk_ticketing/
├── bin/
│   └── helpdesk
├── data/
│   └── sample_tickets.json
├── lib/
│   ├── helpdesk_ticketing.rb
│   └── helpdesk_ticketing/
│       ├── cli.rb
│       ├── errors.rb
│       ├── json_repository.rb
│       ├── ticket.rb
│       ├── ticket_service.rb
│       └── transition_policy.rb
├── test/
│   └── helpdesk_ticketing_test.rb
└── README.md
```

## Uso

Todos los comandos aceptan `--db RUTA` para trabajar con un archivo JSON alternativo:

```bash
ruby case_studies/03_helpdesk_ticketing/bin/helpdesk list
ruby case_studies/03_helpdesk_ticketing/bin/helpdesk list --status=in_progress --priority=high
ruby case_studies/03_helpdesk_ticketing/bin/helpdesk stats
ruby case_studies/03_helpdesk_ticketing/bin/helpdesk create "Caída de DNS interno" "No resuelve nombres locales" "ana@ejemplo.local" critical redes
ruby case_studies/03_helpdesk_ticketing/bin/helpdesk assign TCK-004 "carlos.vega"
ruby case_studies/03_helpdesk_ticketing/bin/helpdesk transition TCK-004 in_progress "Reemplazando cartucho de tóner"
ruby case_studies/03_helpdesk_ticketing/bin/helpdesk transition TCK-004 resolved "Tóner sustituido y página de prueba impresa"
```

## Ejemplo de Sesión en Consola

```text
$ ruby case_studies/03_helpdesk_ticketing/bin/helpdesk list --priority=critical
TCK-003 | [RESOLVED] (critical) Error 502 en entorno de preproducción | req: sofia.navarro@ejemplo.local | tech: carlos.vega

$ ruby case_studies/03_helpdesk_ticketing/bin/helpdesk stats
Estadísticas de Mesa de Ayuda (Total: 4)
Por estado: in_progress=1, pending=1, resolved=1, open=1
Por prioridad: high=1, low=1, critical=1, medium=1
Por técnico: carlos.vega=2, lucia.rojas=1, unassigned=1
Tiempo medio de resolución: 1800.0s

$ ruby case_studies/03_helpdesk_ticketing/bin/helpdesk transition TCK-004 resolved "Cierre directo"
Error: Transición inválida de open a resolved (permitidos: in_progress)
```

## Ejecución de Pruebas

```bash
bundle exec ruby -Ilib:test case_studies/03_helpdesk_ticketing/test/helpdesk_ticketing_test.rb
```

## Ejercicios de Extensión

1. **Acuerdos de Nivel de Servicio (SLA)**: Añade una política de SLA según la prioridad (p. ej., `:critical` = 1 hora, `:high` = 4 horas) y un método `sla_breached?` en `Ticket`.
2. **Restricción de asignación previa**: Modifica `TransitionPolicy` o `TicketService` para exigir que un ticket tenga `assignee` antes de pasar a `:in_progress`.
3. **Tiempo efectivo de trabajo**: Calcula el tiempo neto en estado `:in_progress` descontando los intervalos en los que el ticket estuvo en `:pending`.
