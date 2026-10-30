# Mixins de auditoría y catálogo iterable con Enumerable y Comparable

## Enunciado inequívoco
Implementa el módulo `Solutions::Intermediate::AuditableSearchableMixins` que provea el mixin `Auditable` para registrar eventos de dominio con marca de tiempo, la clase `CatalogItem` que incluya `Comparable` y `Auditable`, y la colección `CatalogCollection` que incluya `Enumerable` para consultar, filtrar y ordenar productos.

## Contexto del problema
Ruby favorece la composición de comportamientos transversales mediante módulos (`mixins`) en lugar de jerarquías de herencia profunda. Al implementar únicamente `#<=>` e incluir `Comparable`, una entidad obtiene todos los operadores relacionales; al implementar `#each` e incluir `Enumerable`, una colección de dominio adquiere decenas de operaciones funcionales (`select`, `min`, `max`, `sort`, `sum`).

## Requisitos funcionales
1. Definir `AuditEvent = Data.define(:action, :detail, :at)`.
2. Implementar el mixin `Auditable`:
   - `#record_audit(action, detail: "")` añade un `AuditEvent` (con `Time.now.utc`) a la lista interna de eventos de la instancia.
   - `#audit_log` devuelve una copia congelada de los eventos registrados.
   - `#last_audit_action` devuelve el símbolo/cadena `action` del último evento o `nil` si no hay eventos.
3. Implementar `CatalogItem`:
   - Incluye `Comparable` y `Auditable`.
   - `#initialize(sku:, name:, price_cents:, category:, active: true)` registra un evento `:created` en el log de auditoría.
   - `#update_price(new_price_cents)` valida que `new_price_cents > 0`, actualiza `price_cents` y registra un evento `:price_updated` con detalle `"#{old_price}->#{new_price_cents}"`.
   - `#<=>(other)` compara por `[price_cents, sku]` si `other` es un `CatalogItem`, o retorna `nil`.
4. Implementar `CatalogCollection`:
   - Incluye `Enumerable`.
   - `#initialize(items = [])` y `#add(item)` para agregar instancias de `CatalogItem`.
   - `#each(&block)` retorna un `Enumerator` si no se pasa bloque, o cede cada artículo al bloque.
   - `#by_category(category)` retorna un arreglo con los artículos activos de esa categoría ordenados de menor a mayor precio.
   - `#price_range(min_cents:, max_cents:)` retorna los artículos activos cuyo precio esté dentro del rango inclusivo `min_cents..max_cents`.

## Restricciones técnicas
- `CatalogItem#<=>` debe retornar `nil` cuando se compara con un objeto de otro tipo para que Ruby maneje correctamente `ArgumentError` en `<` o `>`.
- `CatalogCollection#each` debe soportar encadenamiento sin bloque (`collection.each.with_index`).

## Ejemplos de entrada y salida
```ruby
mod = Solutions::Intermediate::AuditableSearchableMixins
item_a = mod::CatalogItem.new(sku: "A1", name: "Mouse", price_cents: 2_500, category: :peripherals)
item_b = mod::CatalogItem.new(sku: "B2", name: "Keyboard", price_cents: 5_000, category: :peripherals)
item_a < item_b # => true
item_a.update_price(2_200)
item_a.last_audit_action # => :price_updated

catalog = mod::CatalogCollection.new([item_b, item_a])
catalog.by_category(:peripherals).map(&:sku) # => ["A1", "B2"]
```

## Casos límite
- Comparación de `CatalogItem` con `nil` o con un `Integer` (`item <=> 42` debe evaluar a `nil`).
- Dos artículos con el mismo `price_cents` deben desempatar alfabéticamente por `sku`.
- Artículos con `active: false` deben seguir presentes en `#each`, pero excluirse en `#by_category` y `#price_range`.

## Criterios de aceptación
- `CatalogItem` soporta `<`, `<=`, `==`, `>=`, `>` y `between?` gracias a `Comparable`.
- `CatalogCollection` soporta `map`, `select`, `min`, `max` y `count` gracias a `Enumerable`.
- El historial `#audit_log` de cada artículo es independiente por instancia y no puede mutarse desde fuera.

## Sugerencia de implementación
En `Auditable`, inicializa `@audit_events ||= []` de forma perezosa para no obligar a las clases que incluyen el mixin a invocar `super` en su `#initialize`.
