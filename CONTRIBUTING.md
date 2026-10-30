# Guía de Contribución

Gracias por tu interés en contribuir a **Ruby Practical Lab**. Este repositorio busca mantener un estándar alto de claridad pedagógica, rigor técnico y código idiomático.

## Principios para contribuir

1. **Idioma**: toda la documentación, comentarios explicativos y enunciados se redactan en **español**. Los identificadores de código (clases, módulos, métodos y variables) se escriben en **inglés** siguiendo las convenciones de Ruby.
2. **Cero pseudocódigo**: todo ejemplo, solución o caso de estudio debe ser ejecutable y verificable.
3. **Sin dependencias innecesarias**: el proyecto raíz solo utiliza la biblioteca estándar de Ruby y las gemas *bundled* oficiales (`csv`, `logger`, `benchmark`), además de `minitest`, `rake` y `rubocop` para desarrollo.
4. **Aislamiento de pruebas**: las pruebas que escriban archivos deben utilizar `Dir.mktmpdir` y limpiar sus recursos al terminar.

## Flujo de trabajo

1. Crea una rama descriptiva a partir de `main`:
   ```bash
   git checkout -b feat/nuevo-ejemplo-enumerators
   ```
2. Añade o modifica el ejemplo, ejercicio o caso de estudio asegurándote de incluir `# frozen_string_literal: true` al inicio de cada archivo `.rb`.
3. Si agregas un ejemplo en `examples/NN_modulo/NN_tema.rb`, incluye el encabezado `# = Título del ejemplo` para que `bin/ruby-lab list` lo descubra automáticamente.
4. Ejecuta la suite completa de pruebas y el análisis estático antes de abrir un Pull Request:
   ```bash
   bundle exec rake test
   bundle exec rake test:api
   bundle exec rubocop
   ```

## Criterios de revisión

- El código pasa todas las pruebas en Ruby 3.4+ y 4.0+ sin advertencias (`warning = true`).
- `bundle exec rubocop` finaliza con **0 ofensas**. Si una regla debe deshabilitarse en un ejemplo didáctico para mostrar un antipatrón, acota el `rubocop:disable` a las líneas exactas y explica el motivo en un comentario.

