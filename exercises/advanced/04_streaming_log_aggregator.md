# Agregador de logs en streaming con Enumerator::Lazy

## Enunciado inequívoco
Implementa en `Solutions::Advanced::StreamingLogAggregator` un agregador de archivos y flujos de logs que procese líneas de manera perezosa mediante `Enumerator::Lazy`, extraiga entradas con formato `[YYYY-MM-DD HH:MM:SS] LEVEL service: message`, contabilice ocurrencias por nivel y por servicio, y registre las líneas malformadas sin interrumpir el procesamiento.

## Contexto del problema
Los archivos de registro en producción suelen alcanzar varios gigabytes. Cargar todo el archivo en memoria con `File.read` o `File.readlines` provoca picos de consumo de RAM y errores `NoMemoryError`. Además, un archivo real suele contener trazas truncadas o líneas corruptas que no deben abortar el análisis completo del flujo.

## Requisitos funcionales
1. Definir `LogEntry = Data.define(:timestamp, :level, :service, :message)` y `LogAggregator` dentro de `Solutions::Advanced::StreamingLogAggregator`.
2. Formato válido de línea: `[YYYY-MM-DD HH:MM:SS] LEVEL service: message`, donde:
   - `LEVEL` pertenece a `DEBUG`, `INFO`, `WARN`, `ERROR` o `FATAL`.
   - `service` contiene caracteres alfanuméricos, guiones o guiones bajos (`[a-zA-Z0-9_-]+`).
   - `message` contiene al menos un carácter no vacío.
3. `LogAggregator#lazy_entries(source)` recibe un `IO`, `StringIO` o colección `Enumerable` de líneas y devuelve un `Enumerator::Lazy` que emite únicamente instancias de `LogEntry` válidas.
4. `LogAggregator#aggregate(source, level_filter: nil, service_filter: nil)` recorre el flujo línea por línea usando evaluación perezosa y devuelve un hash con:
   - `:total_lines`: total de líneas no vacías leídas del flujo.
   - `:valid_lines`: cantidad de líneas válidas (que además coinciden con los filtros opcionales `level_filter` y `service_filter`).
   - `:malformed_lines`: cantidad de líneas con formato inválido.
   - `:malformed_samples`: arreglo acotado (máximo `max_samples`, por defecto 5) con hashes `{ line_number:, raw: }` de las primeras líneas inválidas encontradas.
   - `:by_level`: hash `{ "INFO" => n, ... }` con conteos por severidad.
   - `:by_service`: hash `{ "auth" => n, ... }` con conteos por servicio.
5. `LogAggregator#aggregate_file(file_path, **filters)` abre el archivo con `File.open` y delega en `#aggregate`.

## Restricciones técnicas
- Uso obligatorio de `.lazy` (`Enumerator::Lazy`) para procesar el flujo de entrada.
- Mantener el consumo de memoria acotado: no almacenar todas las líneas válidas ni más de `max_samples` líneas malformadas.

## Ejemplos de entrada y salida
```ruby
require "stringio"

raw_logs = <<~LOGS
  [2026-05-10 10:00:01] INFO auth: Usuario autenticado
  línea corrupta sin formato válido
  [2026-05-10 10:00:05] ERROR payments: Timeout en pasarela
LOGS

aggregator = Solutions::Advanced::StreamingLogAggregator::LogAggregator.new
aggregator.aggregate(StringIO.new(raw_logs))
# => {
#   total_lines: 3,
#   valid_lines: 2,
#   malformed_lines: 1,
#   malformed_samples: [{ line_number: 2, raw: "línea corrupta sin formato válido" }],
#   by_level: { "INFO" => 1, "ERROR" => 1 },
#   by_service: { "auth" => 1, "payments" => 1 }
# }
```

## Casos límite
- Flujo vacío o compuesto únicamente por saltos de línea en blanco: devuelve todos los contadores en `0` y hashes vacíos.
- Más de `max_samples` líneas corruptas: `:malformed_lines` refleja el total real pero `:malformed_samples` conserva solo las primeras `max_samples`.
- Uso de `#lazy_entries(source).first(2)` sobre un flujo infinito o extenso: se detiene tras encontrar las 2 primeras entradas válidas.

## Criterios de aceptación
- `lazy_entries` devuelve una instancia de `Enumerator::Lazy`.
- Las líneas malformadas se contabilizan sin lanzar excepciones.
- Los filtros opcionales `level_filter` y `service_filter` restringen los conteos de `:valid_lines`, `:by_level` y `:by_service`.

## Sugerencia de implementación
Extrae un método `.parse_line(line)` con una expresión regular anclada (`\A...\z`) y capturas con nombre (`?<timestamp>`, `?<level>`, `?<service>`, `?<message>`) para reutilizarlo tanto en `#lazy_entries` como en `#aggregate`.
