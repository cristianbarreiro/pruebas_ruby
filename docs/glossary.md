# Glosario Técnico de Ruby

| Término | Definición |
|---|---|
| **Aridad (*Arity*)** | Cantidad de argumentos que acepta un método, bloque, `Proc` o `lambda`. |
| **Bloque (*Block*)** | Fragmento de código delimitado por `{ ... }` o `do ... end` que se pasa a un método e invoca mediante `yield`. No es un objeto por sí mismo salvo que se convierta en `Proc` con `&block`. |
| **Bundled gem** | Gema cuyos archivos se distribuyen junto con la instalación oficial de Ruby, pero que debe declararse explícitamente en el `Gemfile` cuando se usa `Bundler` (por ejemplo `csv`, `logger` y `benchmark` en Ruby 4.0). |
| **Closure (Clausura)** | Función (`block`, `Proc` o `lambda`) que conserva acceso a las variables locales del ámbito léxico donde fue creada, capturándolas por referencia. |
| **`Data.define`** | Constructor introducido en Ruby 3.2 para definir clases de objetos de valor inmutables con igualdad estructural (`==`, `eql?`, `hash`) y deconstrucción para *pattern matching*. |
| **Default gem** | Gema integrada en la biblioteca estándar de Ruby que puede cargarse directamente con `require` incluso bajo `Bundler` sin necesidad de declararla en el `Gemfile` (por ejemplo `json`, `date`, `optparse`). |
| **Duck typing** | Estilo de polimorfismo dinámico donde la validez de un objeto depende de los métodos a los que responde (`respond_to?`) y no de su jerarquía de herencia. |
| **`Enumerable`** | Módulo del núcleo que proporciona más de 50 métodos de recorrido, búsqueda, filtrado y transformación (`map`, `select`, `reduce`, `group_by`) a cualquier clase que implemente `#each`. |
| **`Enumerator::Lazy`** | Variante de `Enumerator` que encadena transformaciones (`map`, `select`, `filter_map`) evaluándolas elemento a elemento bajo demanda, sin crear arrays intermedios completos. |
| **GVL (*Global VM Lock*)** | Mecanismo interno de CRuby (MRI) que garantiza que solo un hilo nativo ejecute bytecode Ruby a la vez por intérprete (o `Ractor`), liberándose durante operaciones bloqueantes de E/S. |
| **Invariante de dominio** | Regla de negocio que debe cumplirse siempre durante la vida de un objeto (por ejemplo, que el stock de un producto nunca sea negativo). |
| **Keyword arguments** | Parámetros nombrados explícitamente en la definición y llamada de un método (`def create(name:, role: :user)`). |
| **Lambda** | Tipo especial de objeto `Proc` con semántica de método: verifica estrictamente la aridad de sus argumentos y su instrucción `return` sale únicamente de la propia lambda. |
| **Mixin** | Módulo diseñado para inyectar comportamiento reutilizable en una clase mediante `include`, `prepend` o `extend` sin recurrir a herencia múltiple de clases. |
| **Objeto de valor (*Value Object*)** | Objeto pequeño e inmutable cuya identidad depende exclusivamente del valor de sus atributos y no de una dirección de memoria o identificador de base de datos. |
| **Pattern matching** | Construcción (`case ... in`) introducida en Ruby 2.7/3.0 que comprueba la estructura de arrays, hashes y objetos y extrae sus componentes en variables locales. |
| **Predicado** | Método que devuelve `true` o `false` y cuyo nombre termina por convención en signo de interrogación (`empty?`, `valid?`). |
| **Refinement** | Mecanismo (`refine` / `using`) para extender o modificar métodos de una clase existente con alcance estrictamente léxico al archivo o módulo donde se activa. |
| **Símbolo (`Symbol`)** | Identificador inmutable e internado en memoria (`:ok`, `:pending`), óptimo para representar nombres internos, estados y claves de hashes. |
| **Truthiness** | Regla de evaluación booleana: en Ruby únicamente `false` y `nil` son falsos (*falsy*); cualquier otro objeto es verdadero (*truthy*). |

