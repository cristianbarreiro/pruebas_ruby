# Búsqueda binaria, detección de duplicados en O(n) y agrupación de anagramas

## Enunciado inequívoco
Implementa el módulo `Solutions::Intermediate::BinarySearchAndDuplicates` con tres algoritmos fundamentales sobre colecciones: `.binary_search(sorted_items, target)` en tiempo $O(\log n)$, `.find_duplicates(items)` en tiempo $O(n)$ preservando el orden de primera aparición duplicada usando `Set`, y `.group_anagrams(words)` agrupando palabras por firma canónica.

## Contexto del problema
Elegir la estructura de datos equivocada degrada drásticamente el rendimiento en producción: buscar repetidamente con `Array#include?` dentro de otro bucle convierte una tarea lineal $O(n)$ en cuadrática $O(n^2)$. Este ejercicio contrasta la búsqueda logarítmica sobre arreglos ordenados con la indexación en tiempo constante $O(1)$ mediante `Set` y `Hash`.

## Requisitos funcionales
1. Implementar `BinarySearchAndDuplicates.binary_search(sorted_items, target)`:
   - Implementar el algoritmo iterativo de búsqueda binaria con punteros `low` y `high`.
   - Retornar el índice entero (`0..n-1`) donde se encuentra `target` o `nil` si no está presente.
2. Implementar `BinarySearchAndDuplicates.find_duplicates(items)`:
   - Recorrer `items` una sola vez apoyándose en `Set` (`seen` y `duplicates`).
   - Retornar un arreglo con los elementos que aparecen 2 o más veces, sin repetirlos en la salida y en el orden en que se detectó su primera duplicación.
3. Implementar `BinarySearchAndDuplicates.group_anagrams(words)`:
   - Normalizar cada palabra en minúsculas (`downcase`) y ordenar sus caracteres para construir la clave canónica.
   - Retornar un arreglo de arreglos con los grupos de anagramas en el orden de aparición de cada grupo.

## Restricciones técnicas
- En `.binary_search`, implementar explícitamente la lógica de punto medio (`mid = (low + high) / 2`) en lugar de delegar en `Array#index`.
- En `.find_duplicates`, prohibido usar `items.select { |item| items.count(item) > 1 }` por ser $O(n^2)$.

## Ejemplos de entrada y salida
```ruby
alg = Solutions::Intermediate::BinarySearchAndDuplicates
alg.binary_search([10, 20, 30, 40, 50], 40)       # => 3
alg.binary_search([10, 20, 30, 40, 50], 25)       # => nil
alg.find_duplicates([3, 1, 4, 1, 5, 3, 1])        # => [1, 3]
alg.group_anagrams(%w[roma amor ramo gato toga])  # => [["roma", "amor", "ramo"], ["gato", "toga"]]
```

## Casos límite
- Arreglo vacío `[]` en cualquiera de las tres funciones: retorna `nil` en `binary_search` y `[]` en las otras dos.
- Búsqueda del primer o último elemento en `binary_search`, o arreglo de un solo elemento.
- Elemento repetido tres o más veces en `find_duplicates`: debe aparecer una única vez en el resultado.

## Criterios de aceptación
- `binary_search` funciona con cualquier tipo comparable (`Integer`, `String`).
- `find_duplicates` opera en tiempo lineal $O(n)$.
- `group_anagrams` agrupa palabras sin distinguir mayúsculas/minúsculas en la firma, conservando las palabras originales en cada subarreglo.

## Sugerencia de implementación
En `find_duplicates`, recuerda que `Set#add?` retorna `nil` si el elemento ya existía en el conjunto y el propio `Set` si fue añadido por primera vez; esto permite escribir el detector en pocas líneas muy expresivas.
