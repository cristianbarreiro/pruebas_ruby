# Caso de Estudio 04: Analizador de Logs en Streaming (`04_log_analyzer`)

Herramienta de línea de comandos y librería en Ruby para procesar archivos de log estructurados en **streaming** (`File.foreach` y `Enumerator::Lazy`), filtrar por rango de fechas, severidad, servicio o texto, detectar patrones de error repetidos y exportar reportes resumidos en formato texto, JSON y CSV.

---

## Formato de Log Soportado

Cada línea válida sigue el esquema:

```text
YYYY-MM-DD HH:MM:SS [LEVEL] service - message
```

Ejemplo:

```text
2026-03-10 08:03:12 [ERROR] order-worker - Timeout conectando a base de datos primaria
```

### Justificación de la Expresión Regular

El parser (`LogAnalyzer::Parser::LOG_PATTERN`) utiliza capturas con nombre y modo extendido (`/x`):

```ruby
LOG_PATTERN = /\A
  (?<timestamp>\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01])\s(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d)\s+
  \[(?<level>DEBUG|INFO|WARN|ERROR|FATAL)\]\s+
  (?<service>[a-zA-Z0-9_.-]+)\s+-\s+
  (?<message>\S.*)
\z/x
```

1. **Anclas estrictas (`\A` y `\z`)**: evitan coincidencias parciales o inyecciones multilínea que ocurrirían con `^` y `$`.
2. **Grupos con nombre (`?<timestamp>`, `?<level>`, `?<service>`, `?<message>`)**: documentan la intención de cada campo dentro de la propia expresión regular y desacoplan el código del orden posicional (`match[1]`, `match[2]`).
3. **Validación acotada sin `DateTime.parse` por línea**: validar rangos de mes (`01..12`), día (`01..31`) y hora (`00..23:59:59`) directamente en la expresión regular evita instanciar objetos `Time` o `DateTime` en cada línea, reduciendo drásticamente la presión sobre el recolector de basura (GC). Además, el formato ISO 8601 (`YYYY-MM-DD`) permite comparar fechas lexicográficamente como cadenas.
4. **Tolerancia a líneas malformadas**: cuando una línea está truncada o corrupta, `Parser#parse_line` devuelve `nil` y `Analyzer` incrementa el contador `malformed_lines` sin abortar el procesamiento del archivo.

---

## Limitaciones Conocidas

- **Logs multilínea (stacktraces)**: cada salto de línea se evalúa de forma independiente; las trazas de pila que ocupan varias líneas sin cabecera completa se contabilizan como líneas malformadas.
- **Validación calendárica simplificada**: el patrón valida rangos `01..31` para los días sin comprobar años bisiestos ni meses de 30 días, priorizando el rendimiento en archivos grandes.
- **Cardinalidad de mensajes únicos**: aunque el archivo se lee en streaming (`O(1)` por línea leída), el diccionario de frecuencias almacena en memoria los mensajes distintos que coinciden con el filtro.

---

## Uso desde la Terminal

```bash
# Resumen general en texto plano
ruby case_studies/04_log_analyzer/bin/log-analyzer case_studies/04_log_analyzer/data/sample_app.log

# Filtrar únicamente errores de un servicio en un rango de fechas
ruby case_studies/04_log_analyzer/bin/log-analyzer \
  --level ERROR \
  --service order-worker \
  --from 2026-03-10 \
  --to 2026-03-12 \
  case_studies/04_log_analyzer/data/sample_app.log

# Exportar reporte en formato JSON o CSV a un archivo
ruby case_studies/04_log_analyzer/bin/log-analyzer \
  --format json \
  --output reporte.json \
  case_studies/04_log_analyzer/data/sample_app.log
```

---

## Pruebas y Benchmark Reproducible

Desde la raíz del repositorio:

```bash
# Ejecutar pruebas del analizador de logs
bundle exec ruby -Ilib:test case_studies/04_log_analyzer/test/log_analyzer_test.rb

# Ejecutar el benchmark sintético (1.000 y 10.000 líneas en Dir.mktmpdir)
bundle exec rake benchmark
```
