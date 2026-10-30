# 01 — Conversor de Temperaturas

## Enunciado inequívoco

Implementa el módulo `Solutions::Beginner::TemperatureConverter` con el método `.convert(value, from:, to:)` capaz de transformar valores numéricos de temperatura entre las escalas `:celsius`, `:fahrenheit` y `:kelvin`, redondeando el resultado a 2 decimales y validando límites físicos como el cero absoluto.

## Contexto del problema

En sistemas de monitoreo ambiental y telemetría industrial, los sensores reportan lecturas en distintas escalas según el fabricante (Celsius en Europa y Latinoamérica, Fahrenheit en equipos estadounidenses y Kelvin en instrumentación científica). Antes de almacenar o comparar las mediciones, un servicio de dominio debe normalizarlas y rechazar lecturas físicamente imposibles (inferiores al cero absoluto, `0 K`) o escalas desconocidas.

## Requisitos funcionales

1. Definir `Solutions::Beginner::TemperatureConverter.convert(value, from:, to:)`.
2. Soportar las escalas `:celsius`, `:fahrenheit` y `:kelvin` (tanto en `from:` como en `to:`).
3. Redondear el valor resultante a 2 cifras decimales (`Float#round(2)`).
4. Si `from` y `to` son la misma escala válida, devolver el valor convertido a `Float` redondeado a 2 decimales (tras validar que no esté por debajo del cero absoluto).
5. Lanzar `ArgumentError` si `value` no es un `Numeric`.
6. Lanzar `ArgumentError` si `from` o `to` no pertenecen al conjunto `[:celsius, :fahrenheit, :kelvin]`.
7. Lanzar `ArgumentError` si la temperatura de entrada equivale a menos de `0 K` (`-273.15 °C` o `-459.67 °F`), empleando una pequeña tolerancia de punto flotante (`-1e-9`) para permitir exactamente el cero absoluto en cualquier escala.

## Restricciones técnicas

- El archivo debe iniciar con `# frozen_string_literal: true`.
- No utilizar gemas externas para conversión de unidades.
- Mantener métodos cortos, claros y sin mutación de estado global.

## Ejemplos de entrada y salida

```ruby
Solutions::Beginner::TemperatureConverter.convert(0, from: :celsius, to: :fahrenheit)
# => 32.0

Solutions::Beginner::TemperatureConverter.convert(100, from: :celsius, to: :kelvin)
# => 373.15

Solutions::Beginner::TemperatureConverter.convert(98.6, from: :fahrenheit, to: :celsius)
# => 37.0

Solutions::Beginner::TemperatureConverter.convert(0, from: :kelvin, to: :celsius)
# => -273.15
```

## Casos límite

- Conversión hacia la misma escala (`from: :celsius, to: :celsius`).
- Temperatura exactamente en el cero absoluto en cualquiera de las tres escalas (`0 K`, `-273.15 °C`, `-459.67 °F`).
- Temperatura ligeramente inferior al cero absoluto (`-0.01 K`, `-273.16 °C`, `-460.0 °F`) que debe lanzar `ArgumentError`.
- Escalas pasadas como `String` o símbolos inválidos (`:rankine`), que deben lanzar `ArgumentError`.
- Valores negativos válidos en Celsius o Fahrenheit (por ejemplo, `-40 °C == -40.0 °F`).

## Criterios de aceptación

- Todas las combinaciones entre `:celsius`, `:fahrenheit` y `:kelvin` producen resultados exactos a 2 decimales.
- Se lanza `ArgumentError` con un mensaje descriptivo ante escalas desconocidas, entradas no numéricas o temperaturas bajo el cero absoluto.
- El archivo es ejecutable directamente con `ruby solutions/beginner/01_temperature_converter.rb` y pasa RuboCop sin ofensas.

## Sugerencia de implementación

En lugar de codificar las 9 combinaciones posibles entre pares de escalas (`3 x 3`), utiliza el **Kelvin** (o Celsius) como unidad pivote interna:

1. Convierte primero desde la escala de origen (`from`) hacia Kelvin.
2. Verifica en ese único punto que el valor en Kelvin no sea menor que `0`.
3. Convierte desde Kelvin hacia la escala de destino (`to`) y aplica `.round(2)`.
