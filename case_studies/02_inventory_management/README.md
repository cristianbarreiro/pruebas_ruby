# Caso de Estudio 02: Sistema de Gestión de Inventario (`02_inventory_management`)

## Problema

Las pequeñas y medianas operaciones de almacén suelen registrar existencias en hojas de cálculo sin validaciones de negocio, lo que provoca tres fallos recurrentes:

1. **Saldos negativos** por registrar salidas mayores que el stock real.
2. **Pérdida de trazabilidad** al sobrescribir la cantidad de un producto sin conservar el historial de entradas y salidas ni el motivo del ajuste.
3. **Corrupción de datos** cuando el archivo de persistencia se trunca a mitad de una escritura.

Este caso de estudio implementa un motor de inventario con reglas de dominio desacopladas de la interfaz de línea de comandos y de la persistencia en disco.

## Diseño y Arquitectura

El proyecto separa estrictamente tres capas:

- **Dominio (`Product`, `StockMovement`, `Errors`)**:
  - `Product` valida SKU obligatorio (normalizado en mayúsculas), precio en centavos estrictamente positivo (`price_cents > 0`), y `stock`/`min_stock` no negativos. Expone `low_stock?`, `inventory_value_cents` y `apply_movement`.
  - `StockMovement` se modela como un valor inmutable mediante `Data.define(:sku, :type, :quantity, :reason, :timestamp)` para movimientos `:in` y `:out`.
  - `Errors` agrupa las excepciones específicas del negocio (`ValidationError`, `NotFoundError`, `InsufficientStockError`, `DuplicateSkuError`).
- **Aplicación (`InventoryService`)**:
  - Coordina alta, actualización, consulta y baja de productos.
  - Registra entradas (`record_entry`) y salidas (`record_exit`) impidiendo saldos negativos.
  - Ofrece búsqueda por SKU/nombre/categoría (`search`), detección de alertas de reposición (`low_stock_products`) y reporte financiero agrupado por categoría (`valuation_report`).
- **Infraestructura e Interfaz (`JsonRepository`, `CLI`)**:
  - `JsonRepository` persiste productos y movimientos de forma atómica escribiendo primero en un archivo temporal (`.tmp`) y aplicando `File.rename`.
  - `CLI` recibe flujos `input:` y `output:` inyectables para facilitar las pruebas automatizadas sin depender de procesos externos.

```text
case_studies/02_inventory_management/
├── bin/
│   └── inventory
├── data/
│   └── sample_inventory.json
├── lib/
│   ├── inventory_management.rb
│   └── inventory_management/
│       ├── cli.rb
│       ├── errors.rb
│       ├── inventory_service.rb
│       ├── json_repository.rb
│       ├── product.rb
│       └── stock_movement.rb
├── test/
│   └── inventory_management_test.rb
└── README.md
```

## Uso

Todos los comandos aceptan el parámetro opcional `--db RUTA` para indicar el archivo JSON de persistencia (por defecto usa `data/sample_inventory.json`):

```bash
ruby case_studies/02_inventory_management/bin/inventory report
ruby case_studies/02_inventory_management/bin/inventory low-stock
ruby case_studies/02_inventory_management/bin/inventory search conectividad
ruby case_studies/02_inventory_management/bin/inventory add MOU-OPT-01 "Mouse Óptico Pro" perifericos 2500 12 5
ruby case_studies/02_inventory_management/bin/inventory stock-in MOU-OPT-01 8 "Recepción orden #402"
ruby case_studies/02_inventory_management/bin/inventory stock-out MOU-OPT-01 3 "Despacho pedido #891"
ruby case_studies/02_inventory_management/bin/inventory delete MOU-OPT-01
```

## Ejemplo de Sesión en Consola

```text
$ ruby case_studies/02_inventory_management/bin/inventory low-stock
Alertas de stock bajo (2):
HUB-USBC-7P | Hub USB-C 7 en 1 con Ethernet (conectividad) | $45.00 | stock: 4 (min: 8) [LOW STOCK]
MON-IPS-27 | Monitor IPS 27 Pulgadas QHD (monitores) | $299.00 | stock: 3 (min: 5) [LOW STOCK]

$ ruby case_studies/02_inventory_management/bin/inventory report
Reporte de valoración de inventario
SKUs totales: 5 | Unidades: 83
Valor total: $4408.00 | Alertas: 2
  - almacenamiento: 1 SKUs, 20 uds, $1560.00
  - conectividad: 2 SKUs, 46 uds, $705.00
  - monitores: 1 SKUs, 3 uds, $897.00
  - perifericos: 1 SKUs, 14 uds, $1246.00

$ ruby case_studies/02_inventory_management/bin/inventory stock-out MON-IPS-27 10 "Venta corporativa"
Error: Stock insuficiente para MON-IPS-27 (disponible: 3, solicitado: 10)
```

## Ejecución de Pruebas

```bash
bundle exec ruby -Ilib:test case_studies/02_inventory_management/test/inventory_management_test.rb
```

## Ejercicios de Extensión

1. **Transferencias entre almacenes**: Añade soporte para múltiples ubicaciones y un método `transfer_stock` que registre una salida en el almacén origen y una entrada en el destino dentro de una misma operación.
2. **Costo promedio ponderado (WAC)**: Extiende `StockMovement` de tipo `:in` para incluir el costo unitario de compra y recalcula automáticamente el costo promedio del producto.
3. **Exportación CSV de kardex**: Implementa un comando `kardex SKU` en la CLI que muestre el historial cronológico de movimientos de un producto con el saldo acumulado tras cada operación.
