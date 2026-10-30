# 09 — Generador de Series Numéricas

## Enunciado inequívoco

Implementa el módulo `Solutions::Beginner::NumberSeriesGenerator` con tres métodos clásicos de generación de secuencias y reducción numérica: `.fizz_buzz(limit, rules: { 3 => "Fizz", 5 => "Buzz" })`, `.collatz_sequence(start)` y `.sum_of_multiples(limit, factors: [3, 5])`.

## Contexto del problema

El dominio de rangos, iteradores perezosos o colecciones y transformaciones numéricas es la base del pensamiento algorítmico en Ruby. Parametrizar las reglas de divisibilidad permite además desacoplar la lógica del clásico problema de constantes fijas.

## Requisitos funcionales

1. `.fizz_buzz(limit, rules: { 3 => "Fizz", 5 => "Buzz" })`:
   - Valida que `limit` sea un `Integer >= 1` y que `rules` sea un `Hash` no vacío cuyas claves sean enteros positivos (`>= 1`).
   - Recorre los números de `1` a `limit` inclusive.
   - Para cada número, concatena las etiquetas de `rules` cuyos divisores dividan exactamente al número (`(num % divisor).zero?`), respetando el orden de inserción de `rules`.
   - Si ninguna regla aplica, convierte el número a `String` (`num.to_s`).
   - Devuelve el `Array` de `String` resultante.
2. `.collatz_sequence(start)`:
   - Valida que `start` sea un `Integer >= 1`.
   - Genera la secuencia de Collatz comenzando en `start` hasta llegar a `1`:
     - Si el número actual es par, el siguiente es `num / 2`.
     - Si el número actual es impar, el siguiente es `(3 * num) + 1`.
   - Devuelve el `Array` de enteros incluyendo tanto `start` como el `1` final.
3. `.sum_of_multiples(limit, factors: [3, 5])`:
   - Valida que `limit` sea un `Integer >= 1` y que `factors` sea un `Array` no vacío de enteros positivos (`>= 1`).
   - Calcula la suma de todos los enteros en el rango `1...limit` (estrictamente menores que `limit`, o `1..limit` según convención: aquí definimos **de `1` hasta `limit` inclusive**, `1..limit`) que sean múltiplos de **al menos uno** de los números en `factors`, sin sumar dos veces un número que sea múltiplo de varios factores.
4. Cualquier argumento inválido (`<= 0`, no entero, colecciones de factores/reglas vacías) debe lanzar `ArgumentError`.

## Restricciones técnicas

- El archivo debe iniciar con `# frozen_string_literal: true`.
- Usar iteradores expresivos de Ruby (`(1..limit).map`, `select`, `sum`, `any?`) en lugar de contadores manuales con `for`.

## Ejemplos de entrada y salida

```ruby
Solutions::Beginner::NumberSeriesGenerator.fizz_buzz(5)
# => ["1", "2", "Fizz", "4", "Buzz"]

Solutions::Beginner::NumberSeriesGenerator.collatz_sequence(6)
# => [6, 3, 10, 5, 16, 8, 4, 2, 1]

Solutions::Beginner::NumberSeriesGenerator.sum_of_multiples(10, factors: [3, 5])
# => 33  (3 + 5 + 6 + 9 + 10)
```

## Casos límite

- `fizz_buzz` con reglas personalizadas como `{ 2 => "Par", 3 => "Tres" }` para `limit = 6` (`"ParTres"` en el 6).
- `collatz_sequence(1)`, que debe devolver `[1]` inmediatamente sin entrar en un ciclo infinito `1 -> 4 -> 2 -> 1`.
- `sum_of_multiples` cuando ningún número en `1..limit` es múltiplo de los factores (por ejemplo `limit = 2, factors: [3, 5]` -> `0`).
- Números `0`, negativos, `Float` o `nil`, que deben lanzar `ArgumentError`.

## Criterios de aceptación

- `fizz_buzz` soporta tanto las reglas por defecto como diccionarios de reglas personalizados.
- `collatz_sequence` termina siempre en `1` y devuelve todos los pasos intermedios.
- `sum_of_multiples` suma los múltiplos en `1..limit` sin duplicar múltiplos comunes (como `15` para `3` y `5`).
- Se lanza `ArgumentError` ante entradas no enteras o menores que `1`.

## Sugerencia de implementación

En `fizz_buzz`, para cada número filtra `rules` con `each_with_object(+"")` o `filter_map` y usa `label.empty? ? num.to_s : label`. En `sum_of_multiples`, filtra `(1..limit).select { |num| factors.any? { |factor| (num % factor).zero? } }.sum`.
