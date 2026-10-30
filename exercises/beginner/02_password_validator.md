# 02 — Validador de Contraseñas

## Enunciado inequívoco

Implementa el módulo `Solutions::Beginner::PasswordValidator` con el método `.validate(password)` que evalúe una contraseña según políticas de seguridad estándar y devuelva un `Hash` con la estructura `{ valid: true/false, errors: [...] }`.

## Contexto del problema

Durante el registro de usuarios o rotación de credenciales, no basta con rechazar una contraseña mediante un booleano: la interfaz de usuario necesita conocer **todas** las reglas incumplidas simultáneamente para mostrar retroalimentación clara al usuario en un solo intento.

## Requisitos funcionales

1. Definir `Solutions::Beginner::PasswordValidator.validate(password)`.
2. Lanzar `ArgumentError` si `password` no es una instancia de `String`.
3. Verificar todas las reglas siguientes de forma acumulativa:
   - Longitud mínima de 8 caracteres.
   - Al menos una letra mayúscula (`A-Z`).
   - Al menos una letra minúscula (`a-z`).
   - Al menos un dígito numérico (`0-9`).
   - Al menos un símbolo o carácter especial (cualquier carácter que no sea letra, dígito ni espacio en blanco).
   - Sin espacios en blanco (`/\s/`).
4. Devolver `{ valid: errors.empty?, errors: errors }` donde `errors` es un `Array` de `String` (o `Symbol`/`String` descriptivos en español) con un elemento por cada regla incumplida, en orden determinista.

## Restricciones técnicas

- El archivo debe iniciar con `# frozen_string_literal: true`.
- No detener la validación en el primer error; deben reportarse todos los incumplimientos presentes en la cadena.
- Expresar las reglas de forma declarativa (por ejemplo, una colección inmutable de reglas) para evitar condicionales extensos.

## Ejemplos de entrada y salida

```ruby
Solutions::Beginner::PasswordValidator.validate("Segura#2026")
# => { valid: true, errors: [] }

Solutions::Beginner::PasswordValidator.validate("abc")
# => {
#   valid: false,
#   errors: [
#     "Debe tener al menos 8 caracteres",
#     "Debe incluir al menos una letra mayúscula",
#     "Debe incluir al menos un dígito",
#     "Debe incluir al menos un símbolo"
#   ]
# }
```

## Casos límite

- Cadena vacía `""` (falla longitud, mayúscula, minúscula, dígito y símbolo, pero no la regla de espacios).
- Contraseña que cumple todos los requisitos excepto que contiene un espacio intermedio o salto de línea (`"Segura# 2026"`).
- Contraseña de exactamente 8 caracteres que cumple todas las reglas (`"Abcdef1!"`).
- Entrada `nil` o numérica, que debe lanzar `ArgumentError`.

## Criterios de aceptación

- Devuelve `{ valid: true, errors: [] }` únicamente cuando se cumplen las 6 reglas.
- Cada regla fallida añade exactamente un mensaje de error al arreglo `errors`.
- Lanza `ArgumentError` ante entradas que no sean `String`.

## Sugerencia de implementación

Modela cada regla como una estructura inmutable (`Data.define(:message, :matcher)`) donde `matcher` sea un `Proc` que reciba la contraseña y devuelva `true` si cumple la condición. Así, validar consiste simplemente en filtrar las reglas cuyo predicado devuelva `false` y extraer sus mensajes con `filter_map`.
