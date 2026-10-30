# Organizador de archivos por lotes con modo simulación (dry-run)

## Enunciado inequívoco
Implementa el módulo `Solutions::Intermediate::BatchFileOrganizer` para clasificar y mover archivos del nivel superior de un directorio hacia subcarpetas temáticas (`images`, `documents`, `code`, `others`) según su extensión, soportando un modo de simulación (`dry_run: true`) que calcule el manifiesto de movimientos sin alterar el sistema de archivos.

## Contexto del problema
Las herramientas de automatización y mantenimiento de archivos deben ser predecibles y seguras. Ofrecer una opción `dry_run` permite inspeccionar exactamente qué archivos se moverían y a qué destino antes de ejecutar cambios reales en disco, facilitando además las pruebas automatizadas deterministas.

## Requisitos funcionales
1. Definir `PlannedMove = Data.define(:file_name, :category, :source_path, :target_path, :executed)`.
2. Clasificar las extensiones (en minúsculas, sin distinción de mayúsculas/minúsculas) según las siguientes reglas:
   - `"images"`: `.jpg`, `.jpeg`, `.png`, `.gif`, `.svg`
   - `"documents"`: `.pdf`, `.md`, `.txt`, `.csv`, `.json`
   - `"code"`: `.rb`, `.py`, `.js`, `.ts`, `.html`, `.css`
   - `"others"`: cualquier otra extensión o archivos sin extensión.
3. Implementar `Organizer#initialize(root_dir)` validando que `Dir.exist?(root_dir)` sea verdadero (`ArgumentError` si no existe).
4. Implementar `Organizer#call(dry_run: false)`:
   - Inspeccionar únicamente los archivos regulares (`File.file?`) en el nivel raíz de `root_dir`, ignorando subdirectorios y archivos ocultos que comiencen por `"."`.
   - Ordenar los nombres de archivo alfabéticamente para garantizar un resultado determinista.
   - Para cada archivo, construir un `PlannedMove` donde `target_path` sea `File.join(root_dir, category, file_name)`.
   - Si `dry_run` es `true`, establecer `executed: false` y no crear carpetas ni mover archivos.
   - Si `dry_run` es `false`, crear el subdirectorio de la categoría (`FileUtils.mkdir_p`), mover el archivo (`FileUtils.mv`) y establecer `executed: true`.
   - Retornar el arreglo de objetos `PlannedMove`.

## Restricciones técnicas
- Usar `File`, `Dir` y `FileUtils` de la biblioteca estándar.
- No procesar recursivamente las subcarpetas ya existentes dentro de `root_dir`.

## Ejemplos de entrada y salida
```ruby
organizer = Solutions::Intermediate::BatchFileOrganizer::Organizer.new("/tmp/downloads")
manifest = organizer.call(dry_run: true)
manifest.first
# => #<data PlannedMove file_name="invoice.pdf", category="documents", source_path="...", target_path="...", executed=false>
```

## Casos límite
- Archivos con extensión en mayúsculas (`"PHOTO.JPG"`) deben clasificarse en `"images"`.
- Archivos sin extensión (`"Makefile"`, `"README"`) deben clasificarse en `"others"`.
- Archivos ocultos (`".DS_Store"`, `".gitignore"`) y subdirectorios deben ignorarse.
- Directorio vacío: retorna `[]` sin crear subcarpetas vacías.

## Criterios de aceptación
- Con `dry_run: true`, los archivos permanecen en su ubicación original y ningún subdirectorio es creado.
- Con `dry_run: false`, cada archivo se mueve a su subcarpeta correspondiente y `File.exist?(move.target_path)` es `true`.

## Sugerencia de implementación
Define un hash constante `CATEGORY_EXTENSIONS` y transpónlo a un diccionario plano extensión -> categoría para resolver la categoría en $O(1)$ con `EXTENSION_MAP.fetch(ext, "others")`.
