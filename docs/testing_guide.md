# Guía de Pruebas con Minitest

El repositorio utiliza **Minitest** como framework de pruebas por su rapidez, simplicidad (las pruebas son clases y métodos estándar de Ruby) y ausencia de magia de metaprogramación.

## 1. Organización de la suite

| Grupo | Comando | Propósito |
|---|---|---|
| Todo el proyecto raíz | `bundle exec rake test` | Ejecuta ejemplos, unitarias, integración, soluciones y casos 01–04 |
| Ejemplos (`test/examples/`) | `bundle exec rake test:examples` | Prueba de humo: ejecuta cada ejemplo en un subproceso limpio |
| Unitarias (`test/unit/`) | `bundle exec rake test:unit` | Prueba `RubyLab::Catalog` y `RubyLab::CLI` en aislamiento |
| Integración (`test/integration/`) | `bundle exec rake test:integration` | Prueba el binario `bin/ruby-lab` de extremo a extremo |
| Soluciones (`test/solutions/`) | `bundle exec rake test:solutions` | Verifica los 28 ejercicios (principiante, intermedio y avanzado) |
| Casos 01–04 | `bundle exec rake test:case_studies` | Prueba dominio, persistencia y CLI de los primeros 4 casos |
| Caso 05 (`REST API`) | `bundle exec rake test:api` | Ejecuta las pruebas HTTP con `Rack::Test` en su propio `Gemfile` |

## 2. Anatomía de una buena prueba

Seguimos el patrón **Arrange – Act – Assert** (Preparar – Actuar – Verificar):

```ruby
def test_transfers_funds_between_accounts
  # Arrange (Preparar)
  source = Account.new(owner: "Ana", balance_cents: 10_000)
  target = Account.new(owner: "Luis", balance_cents: 2_000)

  # Act (Actuar)
  source.transfer_to(target, 3_500)

  # Assert (Verificar)
  assert_equal 6_500, source.balance_cents
  assert_equal 5_500, target.balance_cents
end
```

## 3. Aserciones más utilizadas

- `assert_equal esperado, actual`: compara con `==` (el valor esperado siempre va primero).
- `assert_predicate objeto, :empty?`: invoca un predicado booleano y genera un mensaje claro si falla.
- `assert_includes coleccion, elemento`: verifica pertenencia con `include?`.
- `assert_raises(ClaseError) { ... }`: verifica que el bloque lance la excepción indicada (y devuelve la excepción por si deseas inspeccionar `err.message`).
- `assert_in_delta esperado, actual, 0.001`: compara números `Float` con tolerancia.

## 4. Aislamiento de entrada/salida y archivos

1. **Nunca escribas en rutas fijas del repositorio durante una prueba**: utiliza `Dir.mktmpdir` en `setup`/`teardown` o con un bloque:
   ```ruby
   Dir.mktmpdir("mi_test") do |dir|
     path = File.join(dir, "datos.json")
     store = JsonStore.new(path)
     # ...
   end
   ```
2. **Inyecta `StringIO` para probar interfaces de consola**: en lugar de leer de `$stdin` o imprimir en `$stdout`, pasa objetos `StringIO.new` al constructor de la CLI.
3. **Inyecta el reloj cuando el tiempo importe**: pasa `clock: -> { Time.utc(2026, 10, 29, 12, 0, 0) }` o fechas explícitas para que las pruebas sean 100% deterministas.

