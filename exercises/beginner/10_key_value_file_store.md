# 10 — Almacén de Clave-Valor en Archivo

## Enunciado inequívoco

Implementa el módulo `Solutions::Beginner::KeyValueFileStore` con los métodos `.load_file(path)` y `.save_file(path, hash)` para leer y escribir archivos de configuración planos en formato `clave=valor`.

## Contexto del problema

Muchos servicios utilizan archivos `.env` o `.conf` con pares `clave=valor` por su simplicidad y facilidad de lectura en control de versiones. Un cargador robusto debe ignorar líneas en blanco y comentarios iniciados con `#`, preservar signos `=` que formen parte del valor (por ejemplo en URLs o cadenas codificadas en Base64) y fallar explícitamente si una línea carece de separador o de clave.

## Requisitos funcionales

1. Definir `Solutions::Beginner::KeyValueFileStore.load_file(path)`:
   - Validar que `path` sea un `String` (o `Pathname`) y que el archivo exista (`File.file?(path)`); si no existe o no es válido, lanzar `ArgumentError`.
   - Leer el archivo línea por línea:
     - Ignorar líneas vacías o compuestas únicamente por espacios en blanco.
     - Ignorar líneas cuyo primer carácter no blanco sea `#` (comentarios).
     - En las demás líneas, dividir por el **primer** carácter `=` (`line.split("=", 2)`).
     - Si la línea no contiene `=` o si la clave resultante tras `strip` está vacía, lanzar `ArgumentError` indicando el número de línea o el contenido mal formado.
     - Aplicar `strip` tanto a la clave como al valor y almacenarlos como `String` en el `Hash` de retorno.
   - Si una clave aparece más de una vez, la última ocurrencia sobrescribe a la anterior.
2. Definir `Solutions::Beginner::KeyValueFileStore.save_file(path, hash)`:
   - Validar que `path` sea una ruta válida y `hash` sea una instancia de `Hash`.
   - Validar que ninguna clave (convertida a `String` y `strip`) esté vacía ni contenga `=` o saltos de línea, y que ningún valor contenga saltos de línea; de lo contrario, lanzar `ArgumentError`.
   - Escribir cada par en formato `key=value\n` y devolver el número de pares escritos (`hash.size`).

## Restricciones técnicas

- El archivo debe iniciar con `# frozen_string_literal: true`.
- Cerrar siempre los descriptores de archivo utilizando bloques (`File.foreach`, `File.write` o `File.open(..., "w") { ... }`).
- En las pruebas y demostraciones, utilizar `Dir.mktmpdir` para no dejar archivos residuales en el repositorio.

## Ejemplos de entrada y salida

Archivo `config.env`:
```ini
# Configuración de servidor
HOST = 127.0.0.1
PORT = 3000

DATABASE_URL = postgres://localhost/app?pool=5
```

```ruby
Solutions::Beginner::KeyValueFileStore.load_file("config.env")
# => {
#   "HOST" => "127.0.0.1",
#   "PORT" => "3000",
#   "DATABASE_URL" => "postgres://localhost/app?pool=5"
# }
```

## Casos límite

- Valor vacío después del signo igual (`"TOKEN="` -> `"TOKEN" => ""`).
- Valor que contiene signos `=` adicionales (`"QUERY=a=1&b=2"` -> `"QUERY" => "a=1&b=2"`).
- Archivo compuesto únicamente por comentarios y líneas en blanco (devuelve `{}`).
- Línea sin signo `=` (`"INVALID_LINE"`) o con clave vacía (`"=valor"`), que debe lanzar `ArgumentError`.
- Ruta a un archivo inexistente en `load_file`, que debe lanzar `ArgumentError`.

## Criterios de aceptación

- `load_file` ignora comentarios y líneas vacías, recorta espacios alrededor de claves y valores y preserva `=` dentro del valor.
- `save_file` persiste el `Hash` en disco de modo que un `load_file` posterior recupere exactamente los mismos pares como `String`.
- Se lanza `ArgumentError` ante archivos inexistentes, líneas mal formadas o claves inválidas.

## Sugerencia de implementación

Usa `line.split("=", 2)` al parsear cada línea activa: el segundo argumento `2` garantiza que cualquier `=` adicional permanezca intacto dentro de la parte del valor. Verifica ` line.include?("=")` y `!key.empty?` en un método auxiliar `parse_line(line, line_number)` para mantener el método principal corto.
