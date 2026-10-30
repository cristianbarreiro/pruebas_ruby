# Motor de precios de pedidos por composición

## Enunciado inequívoco
Implementa el módulo `Solutions::Intermediate::OrderPricingEngine` para calcular el desglose financiero en centavos de un pedido (`Order`) compuesto por líneas de producto (`LineItem`), aplicando polimórficamente una estrategia de descuento (`NoDiscount`, `PercentageDiscount` o `ThresholdDiscount`) y una política de impuestos (`TaxPolicy`).

## Contexto del problema
Cuando la lógica de precios, promociones e impuestos se concentra en una única clase `Order` mediante condicionales anidados, añadir nuevas promociones obliga a modificar código probado y multiplica los caminos de prueba. La composición de objetos pequeños con contratos claros (Duck Typing) permite combinar cualquier regla de descuento con cualquier régimen fiscal sin acoplamiento.

## Requisitos funcionales
1. Definir `LineItem = Data.define(:sku, :unit_price_cents, :quantity)` con un método `#subtotal_cents` que retorne `unit_price_cents * quantity`.
2. Definir `PricingBreakdown = Data.define(:subtotal_cents, :discount_cents, :taxable_cents, :tax_cents, :total_cents)`.
3. Implementar las estrategias de descuento con el contrato `#discount_for(subtotal_cents)`:
   - `NoDiscount`: retorna siempre `0`.
   - `PercentageDiscount.new(percent)`: valida `percent` entre `0` y `100`; retorna `(subtotal_cents * percent / 100.0).round`.
   - `ThresholdDiscount.new(threshold_cents:, discount_cents:)`: si `subtotal_cents >= threshold_cents`, retorna `[discount_cents, subtotal_cents].min`; en caso contrario retorna `0`.
4. Implementar `TaxPolicy.new(rate_percent)`:
   - Valida `rate_percent >= 0`.
   - `#tax_for(taxable_cents)` retorna `(taxable_cents * rate_percent / 100.0).round`.
5. Implementar `Order`:
   - `#initialize(items: [], discount: NoDiscount.new, tax_policy: TaxPolicy.new(0))`
   - `#add_item(sku:, unit_price_cents:, quantity: 1)` validando que `unit_price_cents >= 0` y `quantity > 0`.
   - `#subtotal_cents` suma los subtotales de cada `LineItem`.
   - `#pricing_breakdown` retorna una instancia de `PricingBreakdown` donde `discount_cents` nunca supera `subtotal_cents`, `taxable_cents = subtotal_cents - discount_cents`, `tax_cents = tax_policy.tax_for(taxable_cents)` y `total_cents = taxable_cents + tax_cents`.

## Restricciones técnicas
- Todos los importes de entrada y salida deben expresarse en centavos (`Integer`).
- No utilizar herencia entre las estrategias de descuento; usar Duck Typing a través de `#discount_for`.
- Respetar los límites de longitud de método y complejidad de RuboCop.

## Ejemplos de entrada y salida
```ruby
engine = Solutions::Intermediate::OrderPricingEngine
order = engine::Order.new(
  discount: engine::PercentageDiscount.new(10),
  tax_policy: engine::TaxPolicy.new(21)
)
order.add_item(sku: "BOOK-01", unit_price_cents: 2_500, quantity: 2)
breakdown = order.pricing_breakdown
# => #<data PricingBreakdown subtotal_cents=5000, discount_cents=500, taxable_cents=4500, tax_cents=945, total_cents=5445>
```

## Casos límite
- Pedido sin artículos (`subtotal_cents == 0`): todos los campos del desglose deben valer `0`.
- `ThresholdDiscount` cuyo `discount_cents` es mayor que el `subtotal_cents`: el descuento efectivo debe truncarse a `subtotal_cents` para evitar bases imponibles negativas.
- Porcentajes fuera de rango (`percent < 0` o `percent > 100`) o cantidades no positivas deben lanzar `ArgumentError`.

## Criterios de aceptación
- `Order#pricing_breakdown` calcula de forma determinista y sin efectos secundarios el desglose completo.
- Se pueden intercambiar estrategias de descuento e impuestos sin modificar `Order`.

## Sugerencia de implementación
Usa `Data.define` tanto para `LineItem` como para `PricingBreakdown` y delega el cálculo de descuento e impuestos en los colaboradores inyectados en `Order#initialize`.
