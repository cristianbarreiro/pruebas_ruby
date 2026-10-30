# Ruta de Aprendizaje Recomendada

Esta guía propone un recorrido progresivo por **Ruby Practical Lab**, combinando estudio de ejemplos ejecutables, práctica con ejercicios y análisis de casos de estudio reales.

---

## Etapa 1 — Fundamentos del Lenguaje (Semanas 1–2)

**Objetivo**: comprender el modelo de objetos de Ruby, sus tipos básicos, colecciones esenciales y estructuras de control.

1. **Módulo 01 — Fundamentos** (`examples/01_fundamentos/`):
   - Ejecuta `ruby bin/ruby-lab run 01/01` hasta `01/07`.
   - Presta especial atención a la diferencia entre conversiones permisivas (`String#to_i`) y estrictas (`Kernel#Integer`), y a la regla de *truthiness* (solo `false` y `nil` son falsos).
2. **Módulo 02 — Estructuras de datos** (`examples/02_estructuras_de_datos/`):
   - Estudia `Array`, `Hash` y `Set`, y cuándo elegir un `Set` ($O(1)$ en pertenencia) frente a un `Array` ($O(n)$).
3. **Módulo 03 — Control de flujo** (`examples/03_control_de_flujo/`):
   - Condicionales como expresiones, `case/when` con `===`, *pattern matching* (`case/in`) e iteradores.
4. **Práctica (Nivel Principiante)**:
   - Resuelve los ejercicios `01` a `06` de `exercises/beginner/`.

---

## Etapa 2 — Métodos, Bloques y Estilo Funcional (Semanas 3–4)

**Objetivo**: escribir código Ruby expresivo y conciso aprovechando bloques, closures y `Enumerable`.

1. **Módulo 04 — Métodos y bloques** (`examples/04_metodos_y_bloques/`):
   - Parámetros posicionales y nombrados, puertas de ámbito (`def`/`class`/`module`), `yield`, `Proc` vs `lambda` y closures.
2. **Módulo 05 — Programación funcional** (`examples/05_programacion_funcional/`):
   - Transformaciones con `map`, `select`, `filter_map`, `reduce` y `each_with_object`.
   - Inmutabilidad con `freeze` y `Data.define`.
   - Evaluación diferida con `Enumerator::Lazy`.
3. **Módulo 12 — Enumerables e iteradores avanzados** (`examples/12_enumerables_y_iteradores/`):
   - Cómo incluir `Enumerable` y `Comparable` en tus propias clases.
4. **Práctica**:
   - Completa los ejercicios `07` a `10` de `exercises/beginner/` y revisa el **Caso de Estudio 01** (`case_studies/01_cli_expense_tracker/`).

---

## Etapa 3 — Diseño Orientado a Objetos y Robustez (Semanas 5–6)

**Objetivo**: modelar dominios con responsabilidades claras, manejar errores de forma explícita y persistir información con seguridad.

1. **Módulo 06 — Programación orientada a objetos** (`examples/06_programacion_orientada_a_objetos/`):
   - Encapsulamiento, herencia frente a composición, polimorfismo, *duck typing*, principios SOLID y patrones Strategy, Factory y Repository.
2. **Módulo 07 — Módulos y mixins** (`examples/07_modulos_y_mixins/`):
   - Namespaces, `include`, `extend`, `prepend` y orden de búsqueda de métodos (`ancestors`).
3. **Módulo 08 — Excepciones y validación** (`examples/08_excepciones_y_validacion/`):
   - Jerarquías de errores de dominio frente a errores de programación.
4. **Módulo 09 y Módulo 10 — Archivos, datos y expresiones regulares**:
   - Escritura atómica, JSON, CSV, `Pathname` y parseo de texto con `Regexp`.
5. **Práctica (Nivel Intermedio)**:
   - Resuelve los 10 ejercicios de `exercises/intermediate/`.
   - Estudia los **Casos de Estudio 02 y 03** (`02_inventory_management` y `03_helpdesk_ticketing`).

---

## Etapa 4 — Algoritmos, Concurrencia y Arquitectura (Semanas 7–8)

**Objetivo**: analizar rendimiento con criterio, procesar grandes volúmenes de datos y construir servicios mantenibles.

1. **Módulo 11 — Algoritmos y estructuras de datos** (`examples/11_algoritmos_y_estructuras/`):
   - Complejidad temporal/espacial (Big O), búsqueda binaria, ordenamiento, pilas, colas y listas enlazadas.
2. **Módulo 13 — Concurrencia** (`examples/13_concurrencia/`):
   - `Thread`, condiciones de carrera, `Mutex`, `Thread::Queue` y el impacto del GVL.
3. **Módulo 14 — Recursos avanzados** (`examples/14_recursos_avanzados/`):
   - Metaprogramación responsable (`define_method`, `method_missing`), benchmarks con `Benchmark` y gestión de dependencias con Bundler.
4. **Práctica (Nivel Avanzado y Aplicaciones)**:
   - Resuelve los 8 ejercicios de `exercises/advanced/`.
   - Estudia y ejecuta los **Casos de Estudio 04 y 05** (`04_log_analyzer` y `05_rest_api`).

---

## Cómo validar tus propias soluciones

Puedes escribir tus propias soluciones en un directorio separado (con la misma estructura `beginner/`, `intermediate/`, `advanced/`) y ejecutar la suite oficial contra tu código:

```bash
RUBY_LAB_SOLUTIONS_DIR=mi_solucion bundle exec rake test:solutions
```

