# Refactorización de generador de reportes legado con polimorfismo

## Enunciado inequívoco
Implementa el módulo `Solutions::Intermediate::LegacyReportRefactoring` que reemplace un generador de reportes basado en condicionales `case/if` por una arquitectura polimórfica compuesta por objetos de valor `MetricEntry`, un agregador `MetricsSummary` y formateadores intercambiables (`TextFormatter`, `JsonFormatter`, `CsvFormatter`) coordinados por `ReportGenerator`.

## Contexto del problema
En bases de código heredadas es frecuente encontrar clases "Dios" que mezclan el cálculo estadístico de métricas con la concatenación manual de cadenas para texto plano, JSON y CSV mediante sentencias `case format`. Extraer el cálculo a un objeto de resumen y delegar la serialización en formateadores polimórficos aplica el Principio de Abierto/Cerrado (OCP) y el Principio de Responsabilidad Única (SRP).

## Requisitos funcionales
1. Definir `MetricEntry = Data.define(:service, :latency_ms, :success)`.
2. Definir `MetricsSummary = Data.define(:title, :total_requests, :average_latency_ms, :success_rate_percent)`:
   - Implementar `MetricsSummary.from_entries(title:, entries:)` que calcule:
     - `total_requests = entries.size`
     - `average_latency_ms`: promedio redondeado a 2 decimales (`0.0` si `entries` está vacío).
     - `success_rate_percent`: porcentaje de entradas con `success: true` redondeado a 2 decimales (`0.0` si `entries` está vacío).
3. Implementar los tres formateadores con el método `#format(summary)`:
   - `TextFormatter`: retorna `"Report: #{summary.title} | Requests: #{summary.total_requests} | Avg Latency: #{summary.average_latency_ms}ms | Success: #{summary.success_rate_percent}%"`.
   - `JsonFormatter`: retorna una cadena JSON con las claves `"title"`, `"total_requests"`, `"average_latency_ms"` y `"success_rate_percent"`.
   - `CsvFormatter`: retorna dos líneas CSV con cabecera `"title,total_requests,average_latency_ms,success_rate_percent\n"` seguida de la fila de valores.
4. Implementar `ReportGenerator`:
   - `.for_format(format_symbol)` que resuelva `:text`, `:json` o `:csv` mediante un mapa constante de clases formateadoras (lanzando `ArgumentError` si el formato es desconocido).
   - `#initialize(formatter: TextFormatter.new)`
   - `#generate(title:, entries:)` que construya el `MetricsSummary` y delegue en `@formatter.format(summary)`.

## Restricciones técnicas
- No usar estructuras `case` ni cadenas `if/elsif` para seleccionar o ejecutar el formato; emplear un diccionario constante `FORMATTERS` y polimorfismo.
- Requerir `"json"` y `"csv"` de la biblioteca estándar.

## Ejemplos de entrada y salida
```ruby
mod = Solutions::Intermediate::LegacyReportRefactoring
entries = [
  mod::MetricEntry.new(service: "auth", latency_ms: 100, success: true),
  mod::MetricEntry.new(service: "auth", latency_ms: 200, success: false)
]
gen = mod::ReportGenerator.for_format(:text)
gen.generate(title: "Auth SLA", entries: entries)
# => "Report: Auth SLA | Requests: 2 | Avg Latency: 150.0ms | Success: 50.0%"
```

## Casos límite
- Lista de `entries` vacía (`[]`): `total_requests: 0`, `average_latency_ms: 0.0`, `success_rate_percent: 0.0` sin dividir por cero (`ZeroDivisionError`).
- Solicitud de un formato inexistente en `ReportGenerator.for_format(:xml)` debe lanzar `ArgumentError`.
- Inyección de un formateador personalizado en `ReportGenerator.new(formatter: custom)` debe funcionar por Duck Typing.

## Criterios de aceptación
- `MetricsSummary.from_entries` calcula las métricas una sola vez con independencia del formato de salida.
- Los tres formateadores producen salidas consistentes a partir del mismo `MetricsSummary`.

## Sugerencia de implementación
Define `FORMATTERS = { text: TextFormatter, json: JsonFormatter, csv: CsvFormatter }.freeze` para resolver el formateador con `FORMATTERS.fetch(format_symbol.to_sym)`.
