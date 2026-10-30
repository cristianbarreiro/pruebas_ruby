# Repositorio de archivos JSON con escritura atómica

## Enunciado inequívoco
Implementa el módulo `Solutions::Intermediate::JsonFileRepository` con una clase `Repository` que persista registros con claves simbólicas en un archivo JSON en disco usando escrituras atómicas (`Tempfile` + `FileUtils.mv`), provea las operaciones `save`, `find`, `all` y `delete`, y lance `CorruptedStorageError` si el archivo contiene JSON inválido.

## Contexto del problema
Escribir directamente sobre un archivo de datos con `File.write(path, content)` es peligroso: si el proceso se interrumpe a mitad de la escritura o el disco se llena, el archivo queda truncado e ilegible. El patrón de escritura atómica escribe primero el contenido completo en un archivo temporal en el mismo directorio y luego lo renombra sobre el archivo destino mediante `FileUtils.mv`.

## Requisitos funcionales
1. Definir `CorruptedStorageError < StandardError` dentro de `Solutions::Intermediate::JsonFileRepository`.
2. Implementar `Repository#initialize(file_path)`:
   - Asegurar que el directorio padre exista (`FileUtils.mkdir_p`).
   - Si el archivo no existe todavía, no es obligatorio crearlo hasta el primer `save`, o puede inicializarse con `"{}"`.
3. Implementar `Repository#save(record)`:
   - Validar que `record` sea un `Hash` que contenga `:id` o `"id"` no vacío (`ArgumentError` en caso contrario).
   - Normalizar todas las claves del registro a `Symbol`.
   - Persistir el registro indexado por su `id` (como `String`) de manera atómica usando `Tempfile.create` en el directorio del archivo y `FileUtils.mv`.
   - Retornar el registro guardado con claves simbólicas.
4. Implementar `Repository#find(record_id)`:
   - Retornar el hash del registro con claves simbólicas (`symbolize_names: true`) o `nil` si no existe.
5. Implementar `Repository#all`:
   - Retornar un arreglo con todos los registros almacenados (cada uno con claves simbólicas).
6. Implementar `Repository#delete(record_id)`:
   - Eliminar el registro si existe, persistir atómicamente el cambio y retornar el registro eliminado o `nil` si no existía.
7. Si al leer el archivo su contenido no es un objeto JSON válido (`JSON::ParserError` o raíz distinta de `Hash`), lanzar `CorruptedStorageError`.

## Restricciones técnicas
- Usar `json`, `fileutils` y `tempfile` de la biblioteca estándar.
- Asegurar el cierre del `Tempfile` antes de moverlo en Windows (`tempfile.close` antes de `FileUtils.mv` evita errores de bloqueo de archivo `Errno::EACCES`).

## Ejemplos de entrada y salida
```ruby
repo = Solutions::Intermediate::JsonFileRepository::Repository.new("/tmp/users.json")
repo.save(id: "u1", name: "Ada", role: "admin")
repo.find("u1")   # => {id: "u1", name: "Ada", role: "admin"}
repo.all.size     # => 1
repo.delete("u1") # => true
repo.find("u1")   # => nil
```

## Casos límite
- Lectura cuando el archivo aún no existe: `#all` retorna `[]` y `#find` retorna `nil`.
- Archivo corrompido manualmente con `"{{{bad json"` debe lanzar `CorruptedStorageError`.
- Sobrescritura de un registro con el mismo `id` debe actualizar sus atributos sin duplicar entradas.

## Criterios de aceptación
- Ningún archivo temporal residual permanece en el directorio tras `save` o `delete`.
- Compatible con Windows cerrando el descriptor de archivo antes de `FileUtils.mv`.

## Sugerencia de implementación
Extrae un método privado `atomic_write(data_hash)` que cree el archivo temporal en `File.dirname(@file_path)`, escriba el JSON, cierre el descriptor y ejecute `FileUtils.mv(temp.path, @file_path)`.
