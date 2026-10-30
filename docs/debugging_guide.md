# Guía de Depuración y Diagnóstico en Ruby

Cuando un programa no se comporta como esperas o una prueba falla, aplica un proceso sistemático: **reproducir -> aislar -> inspeccionar -> corregir con una prueba**.

## 1. Inspección rápida sin dependencias

- **`p valor` y `pp valor`**: a diferencia de `puts` (que usa `to_s` y oculta la diferencia entre `"42"`, `42` y `:42`), `p` imprime `.inspect` y **devuelve el propio valor**, por lo que puedes insertarlo en medio de una expresión sin romperla:
  ```ruby
  total = p(items.select(&:active?)).sum(&:price_cents)
  ```
- **`Object#tap`**: permite inspeccionar un paso intermedio dentro de una cadena de métodos:
  ```ruby
  result = orders
    .select(&:paid?)
    .tap { |paid| warn "Pagadas: #{paid.size}" }
    .map(&:total_cents)
  ```

## 2. Introspección en tiempo de ejecución

Cuando no sabes de dónde viene un método o qué contiene un objeto:

```ruby
objeto.class                          # Clase exacta del objeto
objeto.class.ancestors                # Cadena de herencia y módulos incluidos
objeto.methods(false)                 # Métodos públicos definidos en su propia clase
objeto.method(:calcular).source_location # [archivo, línea] donde se definió el método
```

`Method#source_location` es especialmente útil cuando trabajas con mixins o gemas y necesitas saber qué módulo definió o sobrescribió un método.

## 3. Lectura de trazas de error (*Backtraces*)

En Ruby, la primera línea muestra el punto exacto donde se lanzó la excepción y las siguientes muestran la pila de llamadas de adentro hacia afuera:

```text
lib/expense_tracker/transaction.rb:88:in 'validate_type!': Tipo inválido: foo (ArgumentError)
  from lib/expense_tracker/transaction.rb:15:in 'build'
  from lib/expense_tracker/ledger.rb:18:in 'record'
```

- Busca la **primera línea que pertenezca a tu propio código** (en `lib/`, `solutions/` o `test/`).
- En Ruby 3.1+ la gema integrada `error_highlight` subraya con `^^^^` la expresión exacta que falló dentro de la línea.

## 4. El depurador interactivo (`debug`) y `binding.irb`

Ruby incluye en su biblioteca estándar la consola interactiva `binding.irb`:

```ruby
def process_order(order)
  binding.irb # Abre una sesión IRB con acceso a las variables locales de este punto
end
```

Comandos útiles dentro de `binding.irb`:
- `ls`: muestra los métodos y variables disponibles en el contexto actual.
- `show_source nombre_metodo`: muestra el código fuente de un método.
- `exit`: continúa la ejecución normal del programa.

## 5. Diagnóstico de rendimiento y memoria

Antes de optimizar, mide (consulta `examples/14_recursos_avanzados/02_benchmarks_y_profiling.rb`):
- Usa `Benchmark.bm` o `Process.clock_gettime(Process::CLOCK_MONOTONIC)` para medir tiempo real sin interferencia del reloj de pared.
- Usa `GC.stat(:total_allocated_objects)` antes y después de un bloque para detectar cuántas asignaciones de objetos genera un algoritmo.

