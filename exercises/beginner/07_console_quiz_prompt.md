# 07 — Prompt Interactivo de Cuestionario en Consola

## Enunciado inequívoco

Implementa el módulo `Solutions::Beginner::ConsoleQuizPrompt` con el método `.ask_until_valid(prompt:, valid_options:, input: $stdin, output: $stdout, max_attempts: 3)` que solicite una respuesta por consola hasta recibir una opción válida o agotar el número máximo de intentos.

## Contexto del problema

Las herramientas de línea de comandos (CLI) deben ser testeables de forma automatizada sin requerir que un humano escriba en el teclado durante la suite de pruebas. Inyectar los flujos `input` y `output` (por defecto `$stdin` y `$stdout`, sustituibles en pruebas por instancias de `StringIO`) permite verificar el comportamiento interactivo de manera determinista.

## Requisitos funcionales

1. Definir `Solutions::Beginner::ConsoleQuizPrompt.ask_until_valid(prompt:, valid_options:, input: $stdin, output: $stdout, max_attempts: 3)`.
2. Validar los parámetros de configuración:
   - `prompt` debe ser un `String` no vacío tras `strip`.
   - `valid_options` debe ser un `Array` no vacío de cadenas o símbolos no vacíos.
   - `max_attempts` debe ser un `Integer` positivo (`>= 1`).
   - Si alguno es inválido, lanzar `ArgumentError` antes de leer de `input`.
3. En cada intento (hasta `max_attempts`):
   - Escribir el `prompt` en `output` (por ejemplo con `output.puts(prompt)` o `output.print`).
   - Leer una línea desde `input` usando `input.gets`.
   - Si `input.gets` devuelve `nil` (fin de flujo / `EOF`), lanzar inmediatamente `ArgumentError` indicando que la entrada terminó inesperadamente.
   - Normalizar la respuesta leída eliminando espacios extremos (`strip`) y convirtiendo a minúsculas (`downcase`).
   - Si la respuesta normalizada coincide con alguna de las opciones de `valid_options` (también normalizadas a `String` en minúsculas sin espacios extremos), devolver dicha opción normalizada (`String`).
   - Si no coincide, escribir en `output` un mensaje de aviso indicando que la opción es inválida y cuáles son las opciones permitidas.
4. Si se agotan los `max_attempts` sin obtener una respuesta válida, lanzar `ArgumentError` indicando que se excedió el máximo de intentos.

## Restricciones técnicas

- El archivo debe iniciar con `# frozen_string_literal: true`.
- Nunca invocar `gets` o `puts` globales directamente; usar siempre los objetos `input` y `output` inyectados.
- Mantener los métodos por debajo de 15 líneas.

## Ejemplos de entrada y salida

```ruby
require "stringio"

input = StringIO.new("tal vez\nSI\n")
output = StringIO.new

answer = Solutions::Beginner::ConsoleQuizPrompt.ask_until_valid(
  prompt: "¿Deseas continuar? (si/no)",
  valid_options: %w[si no],
  input: input,
  output: output,
  max_attempts: 3
)

answer # => "si"
```

## Casos límite

- Usuario responde con espacios y mayúsculas (`"  SI \n"`), que debe aceptarse y devolverse como `"si"`.
- Flujo de entrada vacío (`StringIO.new("")`) donde `gets` devuelve `nil` en el primer intento: lanza `ArgumentError`.
- Usuario falla todos los intentos permitidos (`max_attempts: 2` con dos entradas inválidas): lanza `ArgumentError`.
- `valid_options` vacío `[]` o `max_attempts: 0`: lanza `ArgumentError`.

## Criterios de aceptación

- Devuelve la opción normalizada en minúsculas cuando el usuario acierta dentro del límite de intentos.
- Escribe en `output` tanto la pregunta como los mensajes de error en intentos fallidos.
- Lanza `ArgumentError` ante fin de archivo (`EOF`), intentos agotados o argumentos de configuración inválidos.

## Sugerencia de implementación

Normaliza primero `valid_options` a un arreglo de `String` en minúsculas. Luego usa `max_attempts.times do` para iterar: si una lectura es válida, haz `return normalized_answer` directamente desde el bloque; si el bucle termina normalmente, lanza el `ArgumentError` por límite de intentos excedido.
