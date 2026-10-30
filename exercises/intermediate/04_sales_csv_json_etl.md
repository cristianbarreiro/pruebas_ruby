# Pipeline ETL de ventas de CSV a JSON

## Enunciado inequívoco
Implementa el módulo `Solutions::Intermediate::SalesCsvJsonEtl` capaz de procesar un texto o archivo CSV con registros de ventas (`id,customer,amount_cents,status`), aislar las filas inválidas sin abortar el proceso, agregar los importes de las ventas pagadas (`status == "paid"`) por cliente y exportar el informe consolidado en formato JSON.

## Contexto del problema
En integraciones de datos reales, los archivos CSV provenientes de sistemas externos suelen contener filas corruptas, importes negativos o estados desconocidos. Un pipeline ETL profesional no debe abortar todo el lote ante una fila defectuosa: debe recolectar los errores con su número de línea y motivo, procesar las filas válidas y generar un reporte auditable.

## Requisitos funcionales
1. Requerir las bibliotecas estándar `"csv"` y `"json"`.
2. Definir `RowError = Data.define(:row_number, :raw_id, :reason)`.
3. Definir `EtlReport = Data.define(:total_rows, :valid_paid_rows, :skipped_unpaid_rows, :totals_by_customer, :grand_total_cents, :errors)`.
4. Implementar `SalesCsvJsonEtl.process_csv(csv_text)`:
   - Analizar el CSV con cabeceras (`headers: true`).
   - Validar en cada fila:
     - `id` presente (no vacío).
     - `customer` presente (no vacío).
     - `amount_cents` convertible a entero estrictamente positivo (`Integer(val, 10) > 0`).
     - `status` incluido en `%w[paid pending refunded]`.
   - Si una fila incumple alguna regla, registrar un `RowError` (con `row_number` iniciando en `2` para la primera fila de datos, o índice de fila de datos `1..N` consistente) y continuar.
   - Si la fila es válida y `status == "paid"`, sumar `amount_cents` al acumulado del cliente en `totals_by_customer`.
   - Si la fila es válida pero `status` es `"pending"` o `"refunded"`, incrementar `skipped_unpaid_rows`.
   - Retornar una instancia de `EtlReport`.
5. Implementar `SalesCsvJsonEtl.export_json(csv_text)` que retorne una cadena JSON con las claves `"total_rows"`, `"valid_paid_rows"`, `"skipped_unpaid_rows"`, `"totals_by_customer"`, `"grand_total_cents"` y `"errors"` (arreglo de hashes con `"row_number"`, `"raw_id"`, `"reason"`).

## Restricciones técnicas
- Usar únicamente la biblioteca estándar (`csv` y `json`).
- No lanzar excepciones no controladas ante valores no numéricos en `amount_cents`; capturarlos y convertirlos en `RowError`.

## Ejemplos de entrada y salida
```ruby
csv = <<~CSV
  id,customer,amount_cents,status
  1,Acme,5000,paid
  2,Globex,3000,pending
  3,Acme,bad,paid
  4,Acme,2500,paid
CSV

report = Solutions::Intermediate::SalesCsvJsonEtl.process_csv(csv)
report.totals_by_customer # => {"Acme" => 7500}
report.grand_total_cents  # => 7500
report.errors.size        # => 1
```

## Casos límite
- CSV con solo la cabecera y sin filas de datos: totales en `0`, hashes/arreglos vacíos.
- Espacios en blanco alrededor de campos (`" Acme "`, `" 5000 "`).
- Importes iguales a `0` o negativos (`"-100"`) deben registrarse como error.

## Criterios de aceptación
- Las filas inválidas quedan documentadas en `report.errors` sin impedir la suma de las filas válidas posteriores.
- `SalesCsvJsonEtl.export_json(csv)` produce un JSON válido que al parsearse con `JSON.parse` conserva todas las métricas del reporte.

## Sugerencia de implementación
Separa la validación de una fila individual en un método auxiliar que devuelva la fila normalizada o un `RowError`, manteniendo el bucle de agregación limpio y fácil de leer.
