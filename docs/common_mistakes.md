# Errores Comunes en Ruby y Cómo Evitarlos

Esta guía recopila los errores más frecuentes al programar en Ruby, todos ellos demostrados con código ejecutable en los módulos de `examples/`.

## 1. Suponer que `0`, `""` o `[]` son *falsy*

En Ruby **solo `false` y `nil` son falsos**. Cualquier otro valor (incluido el número `0`, la cadena vacía `""` y el array vacío `[]`) se evalúa como verdadero en un condicional.

```ruby
# Incorrecto: siempre entra en el if aunque count sea 0
if count
  puts "Hay elementos"
end

# Correcto: expresa la condición explícitamente
puts "Hay elementos" if count.positive?
puts "Texto vacío" if text.empty?
```

## 2. Usar `||` para valores por defecto booleanos

Si una opción puede valer `false` legítimamente, `options[:verbose] || true` reemplazará `false` por `true`.

```ruby
# Incorrecto
verbose = options[:verbose] || true

# Correcto
verbose = options.fetch(:verbose, true)
```

## 3. Validar entradas numéricas con `to_i` o `to_f`

`"abc".to_i` devuelve `0` y `"42xyz".to_i` devuelve `42` sin lanzar ningún error.

```ruby
# Incorrecto: oculta datos inválidos convirtiéndolos en 0
quantity = user_input.to_i

# Correcto: falla explícitamente o devuelve nil con exception: false
quantity = Integer(user_input)
```

## 4. Valor por defecto mutable compartido en `Array.new` o `Hash.new`

`Array.new(3, [])` y `Hash.new([])` reutilizan **la misma instancia de Array** para todas las posiciones o claves.

```ruby
# Incorrecto: muta el mismo array compartido
groups = Hash.new([])
groups[:a] << 1 # groups[:b] ahora también parece contener [1]

# Correcto: usa la forma con bloque para crear un array nuevo por clave
groups = Hash.new { |hash, key| hash[key] = [] }
```

## 5. Usar `Float` para dinero

`0.1 + 0.2 == 0.3` evalúa a `false` (`0.30000000000000004`). Representa siempre importes monetarios como **centavos enteros (`Integer`)** o con `BigDecimal`.

## 6. Confundir la precedencia de `and`/`or` con `&&`/`||`

`and` y `or` tienen menor precedencia que el operador de asignación `=`:

```ruby
# Incorrecto: asigna true a result y luego evalúa (true and false)
result = true and false # result vale true

# Correcto
result = true && false  # result vale false
```

## 7. Capturar `Exception` en lugar de `StandardError`

`rescue Exception` intercepta señales del sistema (`SignalException`, `Interrupt`), errores de sintaxis (`SyntaxError`) y falta de memoria (`NoMemoryError`), impidiendo detener el programa limpiamente.

```ruby
# Incorrecto
rescue Exception => err

# Correcto: rescue sin clase (captura StandardError) o aún mejor, la clase específica
rescue JSON::ParserError, Errno::ENOENT => err
```

## 8. Olvidar que `freeze` es superficial

Congelar un `Hash` o `Array` impide añadirle claves o elementos, pero **no congela los objetos mutables que contiene** a menos que también los congeles explícitamente.

