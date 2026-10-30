# 05 — Búsqueda en Catálogo de Productos

## Enunciado inequívoco

Implementa el módulo `Solutions::Beginner::ProductCatalogSearch` con el método `.search(products, query: nil, category: nil, min_price: nil, max_price: nil, in_stock_only: false)` que filtre una colección de productos aplicando criterios opcionales combinables y devuelva los resultados ordenados por precio ascendente y luego por nombre alfabéticamente.

## Contexto del problema

En cualquier tienda en línea o sistema de inventario, el usuario puede combinar múltiples filtros de búsqueda (texto libre, categoría, rango de precios y disponibilidad en stock) o dejar algunos en blanco. El motor de filtrado en memoria debe aplicar únicamente los filtros presentes de manera componible y devolver siempre un orden predecible.

## Requisitos funcionales

1. Definir `Solutions::Beginner::ProductCatalogSearch.search(products, query: nil, category: nil, min_price: nil, max_price: nil, in_stock_only: false)`.
2. Cada producto de `products` es un `Hash` con las claves `:name` (`String`), `:category` (`String` o `Symbol`), `:price` (`Numeric`) y `:stock` (`Integer`).
3. Aplicar los filtros de forma acumulativa (AND lógico):
   - `query`: si no es `nil` ni vacío tras `strip`, filtra productos cuyo `:name` contenga el texto buscado sin distinguir mayúsculas de minúsculas.
   - `category`: si no es `nil`, filtra productos cuya `:category` coincida (comparando en minúsculas como `String` para soportar tanto `Symbol` como `String`).
   - `min_price`: si no es `nil`, filtra productos con `price >= min_price`.
   - `max_price`: si no es `nil`, filtra productos con `price <= max_price`.
   - `in_stock_only`: si es `true`, filtra productos con `stock > 0`.
4. Validar que `products` sea un `Array` y que, si ambos `min_price` y `max_price` están presentes, `min_price <= max_price` (ni sean negativos); de lo contrario, lanzar `ArgumentError`.
5. Ordenar los productos resultantes por `[:price, :name]` en orden ascendente (`[product[:price], product[:name].downcase]`).

## Restricciones técnicas

- El archivo debe iniciar con `# frozen_string_literal: true`.
- No mutar el arreglo `products` original ni los hashes que contiene.
- Mantener la complejidad ciclomática baja separando cada predicado de coincidencia.

## Ejemplos de entrada y salida

```ruby
catalog = [
  { name: "Monitor 27\"", category: "electronics", price: 250.0, stock: 5 },
  { name: "Mouse Inalámbrico", category: "electronics", price: 25.0, stock: 0 },
  { name: "Teclado Mecánico", category: "electronics", price: 80.0, stock: 12 },
  { name: "Silla Ergonómica", category: "furniture", price: 250.0, stock: 3 }
]

Solutions::Beginner::ProductCatalogSearch.search(
  catalog,
  category: :electronics,
  max_price: 300,
  in_stock_only: true
)
# => [
#   { name: "Teclado Mecánico", category: "electronics", price: 80.0, stock: 12 },
#   { name: "Monitor 27\"", category: "electronics", price: 250.0, stock: 5 }
# ]
```

## Casos límite

- Llamada sin filtros opcionales: devuelve todos los productos ordenados por precio y nombre.
- Empate en el precio de dos productos: se desempata ordenando alfabéticamente por `:name`.
- `query` con espacios alrededor o en distinta capitalización (`"  TECLADO "` debe coincidir con `"Teclado Mecánico"`).
- `min_price > max_price` (por ejemplo, `min_price: 100, max_price: 50`), que debe lanzar `ArgumentError`.
- Ningún producto coincide con los filtros: devuelve `[]`.

## Criterios de aceptación

- Todos los filtros opcionales funcionan tanto individualmente como combinados.
- El ordenamiento respeta primero el precio ascendente y en segundo lugar el nombre.
- Se lanza `ArgumentError` cuando `products` no es un `Array`, cuando los precios límite son negativos o cuando `min_price > max_price`.

## Sugerencia de implementación

Agrupa las opciones de filtrado en un objeto o `Data.define` interno (por ejemplo, `Criteria`) o evalúa predicados pequeños como `matches_query?(product, query)`, `matches_category?(product, category)`, `matches_price?(product, min_price, max_price)` y `matches_stock?(product, in_stock_only)`. Luego ordena con `sort_by { |prod| [prod[:price], prod[:name].downcase] }`.
