# 08 — Calculadora de Línea de Factura

## Enunciado inequívoco

Implementa el módulo `Solutions::Beginner::InvoiceLineCalculator` con la estructura inmutable `LineResult` (`Data.define`) y el método `.calculate_line(description, quantity, unit_price_cents:, discount_percent: 0, tax_percent: 19)` para desglosar todos los importes de un renglón de facturación.

## Contexto del problema

En sistemas contables y de facturación electrónica, cada línea de factura requiere un desglose auditable e inmutable: importe bruto, descuento aplicado, importe neto gravable, impuesto calculado y total final. Representar el resultado mediante un objeto de valor inmutable (`Data.define`) evita que capas posteriores alteren accidentalmente los montos ya calculados.

## Requisitos funcionales

1. Definir dentro de `Solutions::Beginner::InvoiceLineCalculator` la constante `LineResult = Data.define(:description, :quantity, :gross_cents, :discount_cents, :net_cents, :tax_cents, :total_cents)`.
2. Definir `.calculate_line(description, quantity, unit_price_cents:, discount_percent: 0, tax_percent: 19)`.
3. Validar los argumentos (lanzando `ArgumentError` si falla alguno):
   - `description`: `String` no vacío tras `strip`.
   - `quantity`: `Integer` estrictamente positivo (`> 0`).
   - `unit_price_cents`: `Integer` mayor o igual a `0`.
   - `discount_percent`: `Numeric` entre `0` y `100` inclusive (`0..100`).
   - `tax_percent`: `Numeric` mayor o igual a `0`.
4. Calcular en centavos enteros (redondeando al entero más cercano con `.round`):
   - `gross_cents = quantity * unit_price_cents`
   - `discount_cents = (gross_cents * (discount_percent / 100.0)).round`
   - `net_cents = gross_cents - discount_cents`
   - `tax_cents = (net_cents * (tax_percent / 100.0)).round`
   - `total_cents = net_cents + tax_cents`
5. Devolver una instancia de `LineResult` con `description.strip` y todos los importes calculados.

## Restricciones técnicas

- El archivo debe iniciar con `# frozen_string_literal: true`.
- Utilizar `Data.define` para `LineResult`.
- Todos los campos monetarios del resultado deben ser instancias de `Integer`.

## Ejemplos de entrada y salida

```ruby
line = Solutions::Beginner::InvoiceLineCalculator.calculate_line(
  "Licencia Anual Pro",
  2,
  unit_price_cents: 10_000,
  discount_percent: 10,
  tax_percent: 19
)

line.gross_cents    # => 20000
line.discount_cents # => 2000
line.net_cents      # => 18000
line.tax_cents      # => 3420
line.total_cents    # => 21420
```

## Casos límite

- Línea sin descuento (`discount_percent: 0`) o exenta de impuestos (`tax_percent: 0`).
- Descuento del 100 % (`discount_percent: 100`), donde `net_cents`, `tax_cents` y `total_cents` deben ser `0`.
- Descripción en blanco `""` o `"   "`, cantidad `0` o negativa, precio negativo o descuento mayor a `100`: todos deben lanzar `ArgumentError`.
- Porcentajes con decimales (por ejemplo `discount_percent: 12.5`) que requieren redondeo al centavo más cercano.

## Criterios de aceptación

- Devuelve una instancia inmutable de `InvoiceLineCalculator::LineResult`.
- Los campos `gross_cents`, `discount_cents`, `net_cents`, `tax_cents` y `total_cents` cumplen las identidades contables (`net = gross - discount` y `total = net + tax`).
- Valida rigurosamente todos los parámetros de entrada lanzando `ArgumentError`.

## Sugerencia de implementación

Crea un método auxiliar privado `percentage_of(amount_cents, percent)` que ejecute `(amount_cents * (percent / 100.0)).round`. Así la lógica aritmética principal queda expresada en cinco líneas legibles y libres de duplicación.
