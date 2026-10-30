# Caso de Estudio 05: API REST JSON de Tickets con Sinatra (`05_rest_api`)

Servicio HTTP REST JSON para la gestión de tickets de soporte técnico, construido con **Sinatra** en estilo modular (`Sinatra::Base`) y aislado con su propio `Gemfile` para no acoplar dependencias web al repositorio principal.

---

## Arquitectura en Capas

```text
case_studies/05_rest_api/
├── .env.example
├── Gemfile
├── Rakefile
├── config.ru
├── lib/
│   ├── rest_api.rb
│   └── rest_api/
│       ├── app.rb                # Capa HTTP (Sinatra::Base, rutas y manejo centralizado de errores)
│       ├── ticket.rb             # Entidad de dominio inmutable y validaciones de valor
│       ├── ticket_repository.rb  # Persistencia JSON atómica o en memoria (STORAGE_PATH)
│       └── ticket_service.rb     # Casos de uso CRUD y filtrado de negocio
└── test/
    └── app_test.rb               # Pruebas de integración HTTP con Rack::Test
```

- **`RestApi::Ticket`**: entidad inmutable que valida campos obligatorios (`title`, `description`) y catálogos cerrados (`status`: `open`, `in_progress`, `resolved`, `closed`; `priority`: `low`, `medium`, `high`, `critical`).
- **`RestApi::TicketRepository`**: persiste los registros en el archivo indicado por `STORAGE_PATH` empleando escritura atómica (`Tempfile` + `FileUtils.mv`) protegida por `Mutex`.
- **`RestApi::TicketService`**: orquesta la lógica CRUD y traduce violaciones de dominio en excepciones específicas (`BadRequestError`, `ValidationError`, `NotFoundError`).
- **`RestApi::App`**: expone los endpoints JSON y mapea cada excepción de dominio a códigos de estado HTTP semánticos (`400`, `404`, `422`, `500`).

---

## Instrucciones de Arranque y Parada

```bash
cd case_studies/05_rest_api

# 1. Instalar dependencias aisladas del servicio
bundle install

# 2. Iniciar el servidor HTTP (por defecto en http://localhost:4567)
STORAGE_PATH=storage/tickets.json bundle exec rackup -p 4567

# Para detener el servidor en la terminal interactiva:
# Presionar Ctrl+C (envía SIGINT a Rack/WEBrick para un cierre ordenado)
```

---

## Endpoints y Ejemplos con `curl`

### 1. `GET /health` — Estado del servicio (`200 OK`)

```bash
curl -i http://localhost:4567/health
```

Respuesta (`200 OK`):

```json
{"status":"ok","service":"tickets-rest-api"}
```

### 2. `POST /tickets` — Crear un ticket (`201 Created`)

```bash
curl -i -X POST http://localhost:4567/tickets \
  -H "Content-Type: application/json" \
  -d '{"title":"Error en pasarela de pagos","description":"Fallo 502 al confirmar orden","priority":"high"}'
```

Respuesta (`201 Created`):

```json
{
  "data": {
    "id": "e4b9f3a0-9a1c-4d2b-8f0e-123456789abc",
    "title": "Error en pasarela de pagos",
    "description": "Fallo 502 al confirmar orden",
    "status": "open",
    "priority": "high",
    "created_at": "2026-03-15T12:00:00Z",
    "updated_at": "2026-03-15T12:00:00Z"
  }
}
```

### 3. `GET /tickets` — Listar y filtrar tickets (`200 OK`)

```bash
curl -s "http://localhost:4567/tickets?status=open&priority=high"
```

### 4. `GET /tickets/:id` — Consultar un ticket por ID (`200 OK` / `404 Not Found`)

```bash
curl -i http://localhost:4567/tickets/e4b9f3a0-9a1c-4d2b-8f0e-123456789abc
```

### 5. `PATCH /tickets/:id` — Actualizar estado o prioridad (`200 OK` / `422 Unprocessable Entity`)

```bash
curl -i -X PATCH http://localhost:4567/tickets/e4b9f3a0-9a1c-4d2b-8f0e-123456789abc \
  -H "Content-Type: application/json" \
  -d '{"status":"in_progress"}'
```

### 6. `DELETE /tickets/:id` — Eliminar un ticket (`204 No Content`)

```bash
curl -i -X DELETE http://localhost:4567/tickets/e4b9f3a0-9a1c-4d2b-8f0e-123456789abc
```

---

## Recomendaciones de Seguridad en Producción

1. **Autenticación y Autorización**: proteger los endpoints mutables (`POST`, `PATCH`, `DELETE`) mediante tokens Bearer (JWT o API keys con rotación) verificados en un middleware Rack.
2. **Límite de tamaño de payload y Rate Limiting**: configurar `Rack::Protection` y `Rack::Attack` (o un proxy inverso como Nginx/Cloudflare) para rechazar cuerpos JSON excesivos y mitigar ataques DoS.
3. **CORS y Cabeceras Seguras**: restringir `Access-Control-Allow-Origin` a dominios explícitos y deshabilitar la exposición de trazas internas (`show_exceptions: false`).

---

## Limitaciones del Almacenamiento JSON Local frente a SQL

| Aspecto | Archivo JSON Local (`STORAGE_PATH`) | Base de Datos SQL (PostgreSQL / SQLite) |
| :--- | :--- | :--- |
| **Concurrencia multiproceso** | `Mutex` solo sincroniza hilos dentro de un único proceso Ruby; múltiples workers sobrescribirían datos. | Control de concurrencia MVCC y bloqueos transaccionales ACID entre múltiples procesos y nodos. |
| **Complejidad de lectura/escritura** | Cada cambio serializa y reescribe toda la colección (`O(N)`). | Índices B-Tree permiten lecturas y escrituras puntuales (`O(log N)`). |
| **Consultas y agregaciones** | Requiere cargar todos los registros en memoria para filtrar. | El planificador SQL ejecuta filtros, paginación y joins en disco/memoria optimizada. |

---

## Ejecución de Pruebas

```bash
# Desde la raíz del repositorio principal:
bundle exec rake test:api

# O directamente dentro de case_studies/05_rest_api:
bundle exec rake test
```
