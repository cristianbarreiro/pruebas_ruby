# 06 — Estadísticas de una Colección

## Enunciado inequívoco

Implementa el módulo `Solutions::Beginner::CollectionStatistics` con el método `.analyze(numbers)` que calcule medidas descriptivas de tendencia central y dispersión para una colección no vacía de números, devolviendo `{ count:, sum:, mean:, median:, modes:, min:, max:, range: }`.

## Contexto del problema

Al procesar lotes de métricas (tiempos de respuesta HTTP, ventas diarias o calificaciones), un resumen estadístico rápido permite detectar valores extremos y entender la distribución sin depender de librerías científicas externas.

## Requisitos funcionales

1. Definir `Solutions::Beginner::CollectionStatistics.analyze(numbers)`.
2. Validar que `numbers` sea un `Array` no vacío donde **todos** los elementos sean instancias de `Numeric` (y no `Float::NAN` ni `Float::INFINITY`). Si `numbers` no es un `Array`, está vacío o contiene algún elemento no numérico (por ejemplo `nil`, `"10"` o `:symbol`), lanzar `ArgumentError`. Note que `Integer` y `Float` son subclases de `Numeric`, pero `TrueClass`/`String` no.
3. Calcular y devolver un `Hash` con las siguientes claves:
   - `:count`: cantidad de elementos (`Integer`).
   - `:sum`: suma total de los elementos.
   - `:mean`: promedio aritmético (`Float` redondeado a 2 decimales con `.round(2)`).
   - `:median`: mediana de los datos ordenados (`Float` redondeado a 2 decimales; si `count` es impar, el elemento central como `Float`; si es par, el promedio de los dos elementos centrales).
   - `:modes`: arreglo ordenado ascendentemente con el valor o valores más frecuentes (`Array`).
   - `:min`: valor mínimo de la colección.
   - `:max`: valor máximo de la colección.
   - `:range`: diferencia entre el máximo y el mínimo (`max - min`).

## Restricciones técnicas

- El archivo debe iniciar con `# frozen_string_literal: true`.
- No mutar el arreglo `numbers` recibido como argumento.
- Descomponer el cálculo de mediana y modas en métodos auxiliares pequeños.

## Ejemplos de entrada y salida

```ruby
Solutions::Beginner::CollectionStatistics.analyze([10, 20, 20, 30, 40])
# => {
#   count: 5,
#   sum: 120,
#   mean: 24.0,
#   median: 20.0,
#   modes: [20],
#   min: 10,
#   max: 40,
#   range: 30
# }
```

## Casos límite

- Colección de un único elemento `[42]`: `mean: 42.0`, `median: 42.0`, `modes: [42]`, `range: 0`.
- Colección con número par de elementos `[1, 2, 3, 4]`: `median: 2.5`.
- Colección multimodal o donde todos tienen la misma frecuencia `[3, 1, 2]`: `modes: [1, 2, 3]` (ordenado ascendentemente).
- Colección con números negativos y decimales.
- Arreglo vacío `[]` o con elementos no numéricos `[1, "2", 3]`: debe lanzar `ArgumentError`.

## Criterios de aceptación

- Calcula con precisión `count`, `sum`, `mean`, `median`, `modes`, `min`, `max` y `range`.
- No modifica el orden del arreglo de entrada original.
- Lanza `ArgumentError` ante entradas vacías o elementos no numéricos.

## Sugerencia de implementación

Ordena primero una copia de la colección (`sorted = numbers.sort`). Con el arreglo ordenado:
- `min` es `sorted.first` y `max` es `sorted.last`.
- Para la mediana, usa `mid = sorted.size / 2`: si `sorted.size.odd?`, toma `sorted[mid].to_f`; si es par, promedia `sorted[mid - 1]` y `sorted[mid]`.
- Para las modas, apóyate en `sorted.tally`, encuentra la frecuencia máxima con `values.max` y selecciona las claves que tengan esa frecuencia.
