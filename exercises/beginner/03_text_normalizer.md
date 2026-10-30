# 03 — Normalizador de Texto

## Enunciado inequívoco

Implementa el módulo `Solutions::Beginner::TextNormalizer` con tres métodos utilitarios para procesamiento de texto en español: `.slugify(text)`, `.word_count(text)` y `.titleize(text)`.

## Contexto del problema

En gestores de contenido (CMS), blogs y catálogos de comercio electrónico en español, un mismo texto de entrada se transforma para distintos propósitos: generar URLs amigables para buscadores (*slugs*), analizar la frecuencia de palabras clave y formatear títulos respetando las partículas cortas del idioma español.

## Requisitos funcionales

1. `.slugify(text)`:
   - Reemplaza vocales acentuadas, con diéresis y la letra `ñ` por sus equivalentes ASCII (`á -> a`, `é -> e`, `í -> i`, `ó -> o`, `ú -> u`, `ü -> u`, `ñ -> n`, incluyendo mayúsculas).
   - Convierte todo el texto a minúsculas.
   - Sustituye cualquier secuencia de caracteres no alfanuméricos (`[^a-z0-9]+`) por un único guion `-`.
   - Elimina guiones al inicio o al final de la cadena resultante.
2. `.word_count(text)`:
   - Extrae todas las palabras compuestas por letras (incluyendo caracteres en español como `áéíóúüñ`) y dígitos, normalizadas a minúsculas.
   - Devuelve un `Hash` donde cada clave es la palabra (`String`) y el valor es el número de apariciones (`Integer`), utilizando `Enumerable#tally`.
3. `.titleize(text)`:
   - Divide el texto en palabras separadas por espacios, convierte cada palabra a minúsculas y capitaliza la primera letra de cada palabra, **excepto** las preposiciones y conjunciones cortas del español (`de`, `del`, `la`, `las`, `el`, `los`, `en`, `y`, `o`, `a`, `con`, `por`, `para`, `sin`, `un`, `una`).
   - La **primera palabra** del título siempre debe ir capitalizada aunque pertenezca a la lista de excepciones.
4. Los tres métodos deben lanzar `ArgumentError` si el argumento recibido no es un `String`.

## Restricciones técnicas

- El archivo debe iniciar con `# frozen_string_literal: true`.
- Usar métodos idiomáticos de `String` y `Enumerable` (`tr`, `gsub`, `scan`, `tally`, `map.with_index`).
- No mutar la cadena recibida por parámetro.

## Ejemplos de entrada y salida

```ruby
Solutions::Beginner::TextNormalizer.slugify("¡Programación en Ruby: Guía Rápida 2026!")
# => "programacion-en-ruby-guia-rapida-2026"

Solutions::Beginner::TextNormalizer.word_count("Ruby es simple, Ruby es expresivo y simple.")
# => { "ruby" => 2, "es" => 2, "simple" => 2, "expresivo" => 1, "y" => 1 }

Solutions::Beginner::TextNormalizer.titleize("el arte de programar en ruby y no morir en el intento")
# => "El Arte de Programar en Ruby y No Morir en el Intento"
```

## Casos límite

- Cadena vacía `""` o compuesta únicamente por espacios/símbolos (`"---!!!"`), que debe devolver `""` en `slugify` y `titleize`, y `{}` en `word_count`.
- Texto con múltiples espacios consecutivos, tabulaciones o saltos de línea.
- Texto donde una preposición aparece en primera posición (`"de la tierra a la luna"` -> `"De la Tierra a la Luna"`).
- Palabras con tildes y eñes tanto en mayúsculas como en minúsculas (`"Árboles y Ñandúes"`).

## Criterios de aceptación

- `slugify` produce únicamente caracteres `[a-z0-9-]` sin guiones duplicados ni en los extremos.
- `word_count` contabiliza palabras sin signos de puntuación y sin distinguir mayúsculas de minúsculas.
- `titleize` respeta las partículas cortas en posiciones intermedias pero capitaliza siempre la primera palabra.
- Cualquier entrada no `String` lanza `ArgumentError`.

## Sugerencia de implementación

Para `slugify`, define dos constantes de traducción con los caracteres acentuados y sus equivalentes ASCII y aplícalas con `String#tr` antes de limpiar con `gsub(/[^a-z0-9]+/, "-")` y `delete_prefix`/`delete_suffix` (o `gsub(/\A-|-+\z/, "")`). Para `titleize`, recorre `words.each_with_index.map` verificando `index.zero?` antes de consultar el conjunto de palabras menores.
