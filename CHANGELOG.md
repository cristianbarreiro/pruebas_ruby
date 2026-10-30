# Changelog

Todos los cambios relevantes de este proyecto se documentan en este archivo.
El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [1.0.0] - 2026-10-29

### Añadido
- CLI interactiva de navegación (`bin/ruby-lab`) y catálogo automático (`RubyLab::Catalog`).
- 14 módulos de ejemplos ejecutables (`examples/01_fundamentos` a `examples/14_recursos_avanzados`) con explicaciones técnicas y errores frecuentes.
- 28 ejercicios progresivos (10 principiante, 10 intermedio, 8 avanzado) en `exercises/` con sus soluciones independientes en `solutions/` y pruebas automatizadas en `test/solutions/`.
- Cinco casos de estudio completos en `case_studies/`:
  1. `01_cli_expense_tracker`: gestor de gastos personales con persistencia JSON atómica y exportación CSV.
  2. `02_inventory_management`: sistema de inventario y control de movimientos de stock.
  3. `03_helpdesk_ticketing`: sistema de tickets de soporte con máquina de estados y métricas de resolución.
  4. `04_log_analyzer`: analizador de logs en streaming con expresiones regulares, reportes y benchmarks.
  5. `05_rest_api`: servicio web REST JSON con Sinatra y suite de integración con `rack-test`.
- Guías técnicas en `docs/`: ruta de aprendizaje, guía de estilo, guía de pruebas, guía de depuración, arquitectura, errores comunes y glosario.
- Configuración reproducible de Minitest, Rake, RuboCop y flujo de integración continua en `.github/workflows/ci.yml`.

