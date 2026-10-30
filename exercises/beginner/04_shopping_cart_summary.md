# 04 — Resumen de Carrito de Compras

## Enunciado inequívoco

Implementa el módulo `Solutions::Beginner::ShoppingCartSummary` con el método `.summarize(items, discount_rate: 0.0, tax_rate: 0.19)` que calcule los totales monetarios de un carrito de compras trabajando exclusivamente en centavos enteros.

## Contexto del problema

En comercio electrónico, operar precios con números de punto flotante (`Float`) introduce errores de redondeo acumulativos (`0.1 + 0.2 != 0.3`). La práctica estándar consiste en representar los importes monetarios en la unidad mínima entera (centavos o pesos sin decimales) y aplicar tasas de descuento e impuestos redondeando al entero más cercano en cada etapa definida.

## Requisitos funcionales

1. Definir `Solutions::Beginner::ShoppingCartSummary.summarize(items, discount_rate: 0.0, tax_rate: 0.19)`.
2. Cada elemento de `items` debe ser un `Hash` con las claves `:name` (`String` no vacío), `:unit_price_cents` (`Integer >= 0`) y `:quantity` (`Integer > 0`).
3. Validar que:
   - `items` sea un `Array`.
   - Cada ítem contenga un nombre válido, `unit_price_cents` entero no negativo y `quantity` entero estrictamente positivo.
   - `discount_rate` sea numérico en el rango `0.0..1.0`.
   - `tax_rate` sea numérico mayor o igual a `0.0`.
   - En caso de cualquier incumplimiento, lanzar `ArgumentError`.
4. Calcular:
   - `subtotal_cents`: suma de `unit_price_cents * quantity` para todos los ítems.
   - `discount_cents`: `(subtotal_cents * discount_rate).round`.
   - Base imponible neta: `subtotal_cents - discount_cents`.
   - `tax_cents`: `((subtotal_cents - discount_cents) * tax_rate).round`.
   - `total_cents`: `(subtotal_cents - discount_cents) + tax_cents`.
   - `line_count`: número de líneas en `items` (`items.size`).
5. Devolver un `Hash` con `{ subtotal_cents:, discount_cents:, tax_cents:, total_cents:, line_count: }`.

## Restricciones técnicas

- El archivo debe iniciar con `# frozen_string_literal: true`.
- Todos los valores monetarios devueltos en el `Hash` deben ser instancias de `Integer`.
- Dividir la validación y el cálculo en métodos privados pequeños para cumplir con las métricas de complejidad.

## Ejemplos de entrada y salida

```ruby
items = [
  { name: "Teclado Mecánico", unit_price_cents: 50_000, quantity: 1 },
  { name: "Cable USB-C", unit_price_cents: 10_000, quantity: 2 }
]

Solutions::Beginner::ShoppingCartSummary.summarize(items, discount_rate: 0.10, tax_rate: 0.19)
# => {
#   subtotal_cents: 70000,
#   discount_cents: 7000,
#   tax_cents: 11970,
#   total_cents: 74970,
#   line_count: 2
# }
```

## Casos límite

- Carrito vacío `[]`: debe ser válido y devolver todos los importes y `line_count` en `0`.
- Producto gratuito o promocional con `unit_price_cents: 0` y `quantity: 1` (válido).
- Producto con `quantity: 0` o negativo, o `unit_price_cents` negativo (debe lanzar `ArgumentError`).
- Descuento del 100 % (`discount_rate: 1.0`), que produce `tax_cents: 0` y `total_cents: 0`.
- Tasas de descuento negativas o mayores a `1.0` (`1.5`), que deben lanzar `ArgumentError`.

## Criterios de aceptación

- Calcula correctamente `subtotal_cents`, `discount_cents`, `tax_cents`, `total_cents` y `line_count`.
- Lanza `ArgumentError` ante ítems mal formados, cantidades no positivas, precios negativos o tasas fuera de rango.
- El impuesto se calcula sobre el subtotal neto (después de restar el descuento).

## Sugerencia de implementación

Crea un método privado `validate_item!(item)` que verifique las tres propiedades del producto y otro `validate_rates!(discount_rate, tax_rate)` para las tasas. Luego usa `items.sum { |item| item[:unit_price_cents] * item[:quantity] }` para obtener el subtotal en una sola expresión clara.
