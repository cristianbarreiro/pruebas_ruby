# Constructor de consultas inmutable (Immutable Query Builder)

## Enunciado inequívoco
Implementa en `Solutions::Advanced::ImmutableQueryBuilder` un constructor de consultas con interfaz fluida (`where`, `order_by`, `paginate`, `execute`) sobre colecciones en memoria que garantice inmutabilidad estricta en cada paso del encadenamiento y devuelva resultados paginados junto con metadatos de paginación.

## Contexto del problema
En aplicaciones empresariales es habitual construir consultas base (por ejemplo, usuarios activos de una organización) y derivar de ellas múltiples consultas especializadas (conteo por rol, listado ordenado para exportación, página actual del panel administrativo). Cuando el constructor de consultas muta su estado interno al encadenar llamadas, reutilizar una consulta base corrompe silenciosamente las consultas posteriores.

## Requisitos funcionales
1. Definir la clase `QueryBuilder` dentro de `Solutions::Advanced::ImmutableQueryBuilder`.
2. `QueryBuilder.new(dataset)` recibe una colección enumerable de hashes y congela una copia superficial para impedir mutaciones externas.
3. `#where(criteria = {}, &predicate)` devuelve una **nueva** instancia de `QueryBuilder` agregando el filtro:
   - Si recibe un hash `criteria`, cada par `campo => condición` debe cumplirse (`===` para soportar valores exactos, rangos `Range`, expresiones regulares `Regexp` o `Proc`, además de pertenencia si la condición es un `Array` o `Set`).
   - Si recibe un bloque `&predicate`, el bloque debe evaluar a verdadero para el registro.
   - Si no se proporciona ni criterios ni bloque, debe lanzar `ArgumentError`.
4. `#order_by(field, direction = :asc)` devuelve una **nueva** instancia con la regla de ordenación añadida:
   - `direction` solo acepta `:asc` o `:desc`; cualquier otro valor lanza `ArgumentError`.
   - Permite encadenar múltiples llamadas a `#order_by` para desempate multinivel.
5. `#paginate(page:, per_page:)` devuelve una **nueva** instancia configurando la página solicitada:
   - `page` y `per_page` deben ser enteros mayores o iguales a `1`; en caso contrario lanza `ArgumentError`.
6. `#execute` evalúa los filtros, el ordenamiento y la paginación, devolviendo un hash con la estructura:
   `{ data: [...], meta: { page:, per_page:, total:, total_pages: } }`.
7. Si no se configuró `#paginate`, `#execute` asume `page: 1` y `per_page` igual al total de elementos filtrados (o `1` si el resultado está vacío, con `total_pages: 0`).

## Restricciones técnicas
- Ningún método de encadenamiento (`where`, `order_by`, `paginate`) puede modificar la instancia receptora (`self`).
- Sin dependencias externas fuera de la biblioteca estándar de Ruby.
- Cumplir con `# frozen_string_literal: true` y las métricas de RuboCop del repositorio.

## Ejemplos de entrada y salida
```ruby
dataset = [
  { id: 1, name: "Ana", role: "admin", score: 95 },
  { id: 2, name: "Luis", role: "editor", score: 82 },
  { id: 3, name: "Marta", role: "admin", score: 88 }
]

base = Solutions::Advanced::ImmutableQueryBuilder::QueryBuilder.new(dataset)
admins = base.where(role: "admin").order_by(:score, :desc).paginate(page: 1, per_page: 1)

admins.execute
# => {
#   data: [{ id: 1, name: "Ana", role: "admin", score: 95 }],
#   meta: { page: 1, per_page: 1, total: 2, total_pages: 2 }
# }

base.execute[:meta][:total]
# => 3 (la consulta base permanece intacta)
```

## Casos límite
- Colección de entrada vacía (`[]`): devuelve `data: []`, `total: 0`, `total_pages: 0`.
- Solicitar una página superior a `total_pages`: devuelve `data: []` manteniendo los metadatos reales de `total` y `total_pages`.
- Ordenamiento por múltiples campos cuando el primer campo empata.
- Filtros combinados por hash (con `Range` o `Array`) y por bloque en llamadas sucesivas a `#where`.

## Criterios de aceptación
- Reutilizar una instancia intermedia para crear dos ramas distintas produce resultados independientes sin interferencia.
- Los errores de validación (`where` vacío, dirección inválida en `order_by`, `page` o `per_page` no positivos) lanzan `ArgumentError`.
- Todas las pruebas automatizadas pasan sin advertencias.

## Sugerencia de implementación
Almacena el estado interno (`records`, `filters`, `orders`, `pagination`) como estructuras inmutables congeladas (`freeze`) y crea un método privado `#spawn(**changes)` que construya una nueva instancia combinando el estado actual con los cambios solicitados.
