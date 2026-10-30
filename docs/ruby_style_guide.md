# Guía de Estilo de Ruby en el Laboratorio

Este documento resume las convenciones adoptadas en **Ruby Practical Lab** y verificadas automáticamente mediante [RuboCop](https://rubocop.org/) en `.rubocop.yml`.

## 1. Formato y codificación

- **Literal de cadenas congelado**: todo archivo `.rb` comienza con `# frozen_string_literal: true`. Esto evita mutaciones accidentales de literales `String` y reduce asignaciones de memoria.
- **Indentación**: 2 espacios por nivel, sin tabuladores.
- **Longitud de línea**: máximo 120 caracteres.
- **Comillas**: se utilizan comillas dobles (`"texto"`) de forma consistente; así no es necesario cambiar de delimitador al añadir interpolaciones (`"Hola, #{name}"`).

## 2. Convenciones de nombres

| Elemento | Convención | Ejemplo |
|---|---|---|
| Variables locales y parámetros | `snake_case` (>= 3 caracteres) | `unit_price`, `total_cents` |
| Métodos | `snake_case` | `calculate_balance` |
| Métodos predicado (booleanos) | Sufijo `?` | `valid?`, `low_stock?`, `income?` |
| Métodos peligrosos o mutadores | Sufijo `!` | `normalize!`, `validate_type!` |
| Clases y módulos | `CamelCase` (`PascalCase`) | `ExpenseTracker`, `JsonStore` |
| Constantes | `SCREAMING_SNAKE_CASE` | `VALID_TYPES`, `DEFAULT_STORAGE` |
| Archivos y directorios | `snake_case` | `ticket_service.rb` |

## 3. Diseño de métodos y clases

- **Métodos pequeños y cohesivos**: máximo 15 líneas por método (excluyendo los scripts demostrativos de `examples/`).
- **Cláusulas de guarda (*guard clauses*)**: retorna temprano cuando se cumpla una condición de salida en vez de anidar bloques `if/else` profundos.
- **Parámetros nombrados (*keyword arguments*)**: prefiérelos cuando un método reciba más de dos parámetros o incluya opciones booleanas:
  ```ruby
  # Evitar
  export(items, true, false)

  # Preferir
  export(items, compress: true, include_headers: false)
  ```
- **Una clase o módulo de nivel superior por archivo**: cada archivo define un único módulo o clase raíz correspondiente a su ruta.

## 4. Colecciones y bloques

- Usa `{ |item| ... }` para bloques de una sola línea (especialmente cuando transforman y devuelven un valor) y `do |item| ... end` para bloques multilínea.
- Usa `Symbol#to_proc` cuando el bloque solo invoca un método sin argumentos: `users.map(&:email)`.
- Prefiere `map`, `select`, `reject`, `filter_map`, `sum`, `tally` y `group_by` sobre bucles `each` que mutan un acumulador externo.

## 5. Excepciones justificadas en `.rubocop.yml`

- `Style/Documentation: Enabled: false`: el propósito de cada clase se explica en la cabecera del archivo y en los README de cada módulo sin forzar comentarios redundantes en clases auxiliares pequeñas.
- `Metrics/BlockLength`: excluido en `Rakefile` y archivos de prueba (`test/`), donde los bloques largos agrupan casos de prueba relacionados.
- `Minitest/MultipleAssertions: Max: 6`: permite verificar las propiedades esenciales de un objeto de dominio dentro de una misma prueba unitaria sin fragmentar artificialmente el escenario.

