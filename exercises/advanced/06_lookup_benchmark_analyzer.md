# Analizador de rendimiento de búsqueda: Array vs Set vs Hash

## Enunciado inequívoco
Implementa en `Solutions::Advanced::LookupBenchmarkAnalyzer` un analizador comparativo basado en la biblioteca estándar `benchmark` y `set` que mida los tiempos reales y de CPU de búsquedas repetidas mediante `Array#include?`, `Set#include?` y `Hash#key?` sobre tamaños de muestra configurables, devolviendo métricas estructuradas (`real_ms`, `cpu_ms`, `hits`, `fastest`, `slowest`, `speedup_ratio`).

## Contexto del problema
Uno de los problemas de rendimiento más frecuentes en código Ruby de producción es ejecutar `Array#include?` dentro de un bucle sobre colecciones que crecen con el tiempo, convirtiendo una operación que debería ser $O(1)$ en $O(N \times M)$. Medir empíricamente el costo real frente a `Set#include?` y `Hash#key?` con datos reproducibles permite fundamentar decisiones de arquitectura y optimización con números concretos.

## Requisitos funcionales
1. Definir `BenchmarkAnalyzer` dentro de `Solutions::Advanced::LookupBenchmarkAnalyzer`.
2. `BenchmarkAnalyzer.compare(collection_size:, lookups_count:, seed: 42)` (y el método de instancia equivalente `#compare`):
   - Valida que `collection_size` y `lookups_count` sean enteros positivos mayores que `0`; en caso contrario lanza `ArgumentError`.
   - Construye una colección base de `collection_size` enteros (`1..collection_size`) y sus representaciones equivalentes en `Array`, `Set` y `Hash` (`{ elemento => true }`).
   - Genera de forma determinista (usando `Random.new(seed)`) una lista de `lookups_count` valores a buscar que combine elementos presentes (en el último cuartil de la colección) y elementos ausentes (superiores a `collection_size`).
   - Mide con `Benchmark.measure` el tiempo de ejecutar todas las búsquedas con `Array#include?`, `Set#include?` y `Hash#key?`.
   - Verifica que las tres estructuras produzcan exactamente el mismo número de aciertos (`hits`).
3. Devuelve un hash estructurado con:
   - `:collection_size` y `:lookups_count`.
   - `:metrics`: hash con las claves `:array`, `:set` y `:hash`, donde cada una contiene `{ real_ms:, cpu_ms:, hits: }`.
   - `:fastest`: símbolo (`:array`, `:set` o `:hash`) con el menor tiempo real.
   - `:slowest`: símbolo con el mayor tiempo real.
   - `:speedup_ratio`: razón numérica entre el tiempo del más lento y el más rápido (`>= 1.0`).

## Restricciones técnicas
- Uso obligatorio de `require "benchmark"` y `require "set"` de la biblioteca estándar.
- Los tiempos `real_ms` y `cpu_ms` deben expresarse en milisegundos como `Float` no negativos redondeados a 4 decimales.

## Ejemplos de entrada y salida
```ruby
report = Solutions::Advanced::LookupBenchmarkAnalyzer::BenchmarkAnalyzer.compare(
  collection_size: 5_000,
  lookups_count: 1_000,
  seed: 42
)

report[:metrics][:array][:hits] == report[:metrics][:set][:hits] # => true
report[:fastest] # => :hash o :set
report[:speedup_ratio] > 1.0 # => true
```

## Casos límite
- `collection_size` muy pequeño (por ejemplo `1` elemento y `1` búsqueda): todas las métricas se calculan sin división por cero en `speedup_ratio` aunque el tiempo medido sea cercano a `0.0`.
- Valores `0`, negativos o no enteros para `collection_size` o `lookups_count`: lanza `ArgumentError`.

## Criterios de aceptación
- El reporte incluye `:metrics` completas para `:array`, `:set` y `:hash` con `:real_ms`, `:cpu_ms` y `:hits`.
- La cantidad de `:hits` coincide exactamente en las tres estructuras de datos para cualquier semilla.
- `:fastest` y `:slowest` identifican correctamente las estrategias de menor y mayor duración.

## Sugerencia de implementación
Para evitar divisiones por cero cuando los tiempos medidos en muestras diminutas son muy cercanos a cero, aplica un piso mínimo (por ejemplo `1e-6` segundos) al denominador al calcular `:speedup_ratio`.
