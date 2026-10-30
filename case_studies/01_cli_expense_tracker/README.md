# Caso de Estudio 01 — CLI Expense Tracker (Gestor de Gastos Personales)

Aplicación de línea de comandos para registrar, buscar, filtrar, resumir y exportar ingresos y gastos personales.

## Problema que resuelve

Llevar un control fiable de finanzas personales desde la terminal sin depender de hojas de cálculo manuales ni servicios externos, garantizando exactitud aritmética en los importes y persistencia segura en disco.

## Decisiones de diseño

1. **Importes en centavos (`Integer`)**: evita los errores clásicos de punto flotante (`0.1 + 0.2 != 0.3`). Los valores se convierten a centavos en la frontera de entrada (`Transaction.build`) y solo se formatean como decimales al presentarlos.
2. **Entidades inmutables con `Data.define`**: `Transaction` y `Ledger::Summary` son objetos de valor inmutables.
3. **Separación en tres capas**:
   - **Dominio** (`Transaction`, `Ledger`): validaciones, filtros combinables y cálculo de balances.
   - **Persistencia e intercambio** (`JsonStore`, `CsvExporter`): escritura atómica mediante `Tempfile` + `FileUtils.mv` para impedir archivos truncados ante fallos.
   - **Presentación** (`CLI`): parseo de opciones con `OptionParser` e inyección de flujos (`out:`, `err:`) para facilitar pruebas deterministas sin subprocesos.

## Conceptos de Ruby aplicados

- `Data.define` (objetos de valor inmutables).
- `OptionParser` de la biblioteca estándar para interfaces CLI.
- `JSON` y `CSV` con manejo explícito de excepciones (`JSON::ParserError` -> `DataCorruptError`).
- Escritura atómica con `Tempfile` y `FileUtils`.
- Colecciones y `Enumerable` (`select`, `sum`, `each_with_object`, `sort_by`).

## Ejecución y sesión de consola de ejemplo

Consultar el archivo de ejemplo incluido:

```bash
ruby case_studies/01_cli_expense_tracker/bin/expense-tracker list --storage case_studies/01_cli_expense_tracker/data/sample_expenses.json
```

Salida esperada:

```text
2026-10-01 | a1b2c3d4 | +$  1850.00 | Salario        | Nómina mensual de octubre
2026-10-03 | a1b2c3d4 | -$   620.00 | Vivienda       | Alquiler mensual
2026-10-08 | a1b2c3d4 | -$   145.50 | Alimentación   | Compra semanal supermercado
2026-10-12 | a1b2c3d4 | -$    42.00 | Transporte     | Recarga tarjeta de transporte público
2026-10-18 | a1b2c3d4 | +$   320.00 | Freelance      | Consultoría de optimización SQL
```

Obtener el resumen financiero:

```bash
ruby case_studies/01_cli_expense_tracker/bin/expense-tracker summary --storage case_studies/01_cli_expense_tracker/data/sample_expenses.json
```

```text
Operaciones: 5
Ingresos:    +$2170.00
Gastos:      -$807.50
Balance:      $1362.50
Por categoría:
  Alimentación   $-145.50
  Freelance      $320.00
  Salario        $1850.00
  Transporte     $-42.00
  Vivienda       $-620.00
```

Registrar un nuevo gasto y exportar a CSV:

```bash
ruby case_studies/01_cli_expense_tracker/bin/expense-tracker add --type expense --amount 25.90 --category Libros --desc " Libro de diseño en Ruby" --date 2026-10-20
ruby case_studies/01_cli_expense_tracker/bin/expense-tracker export-csv --out tmp/octubre.csv
```

## Pruebas

```bash
bundle exec ruby -Ilib:test case_studies/01_cli_expense_tracker/test/expense_tracker_test.rb
```

## Ejercicios de ampliación

1. Añadir presupuestos mensuales por categoría y alertar al superarlos.
2. Soportar importación masiva desde archivos CSV bancarios con detección de duplicados por hash.
3. Incorporar soporte multimoneda mediante una tabla local de tasas de cambio.

