# Ruby Practical Lab (`ruby-practical-lab`)

Laboratorio práctico, ruta de aprendizaje y portafolio de ingeniería de software en **Ruby**. Diseñado para aprender y dominar el lenguaje desde sus fundamentos hasta patrones arquitectónicos, concurrencia y servicios web mediante **ejemplos ejecutables**, **28 ejercicios progresivos con soluciones verificadas** y **5 casos de estudio realistas**.

---

## Objetivos y qué se aprende con este repositorio

1. **Dominar el modelo de objetos y la sintaxis idiomática de Ruby**: tipos básicos, conversiones estrictas vs. permisivas, colecciones (`Array`, `Hash`, `Set`), *truthiness* y *pattern matching* (`case/in`).
2. **Programación funcional y colecciones avanzadas**: bloques, `yield`, `Proc` vs. `lambda`, closures, `Enumerable`, objetos de valor inmutables con `Data.define` y evaluación diferida con `Enumerator::Lazy`.
3. **Diseño orientado a objetos pragmático**: encapsulamiento, composición sobre herencia, *duck typing*, mixins, principios SOLID aplicados con criterio e inyección de dependencias (Strategy, Factory, Repository).
4. **Ingeniería robusta**: jerarquías de excepciones de dominio, escritura atómica de archivos (`Tempfile` + `rename`), procesamiento de CSV/JSON, expresiones regulares seguras, algoritmos, estructuras de datos, concurrencia con `Thread`/`Mutex`/`Queue`, metaprogramación y benchmarks.
5. **Construcción de aplicaciones mantenibles**: separación entre dominio, persistencia e interfaz (CLI y HTTP REST API), pruebas automatizadas deterministas con **Minitest** y análisis estático con **RuboCop**.

---

## Requisitos y versiones compatibles

| Componente | Versión requerida / verificada | Notas |
|---|---|---|
| **Ruby** | `>= 3.4` (referencia `.ruby-version`: `4.0.9`, verificado localmente en `4.0.7`) | Compatible con las ramas estables Ruby 3.4 y Ruby 4.0 |
| **Bundler** | `>= 2.5` / `4.0` | Incluido con Ruby |
| **Sistema Operativo** | Linux, macOS, Windows (RubyInstaller + MSYS2) | Las pruebas son multiplataforma |

---

## Instalación paso a paso

1. **Clona el repositorio y entra al directorio**:
   ```bash
   git clone https://github.com/tu-usuario/pruebas_ruby.git
   cd pruebas_ruby
   ```
2. **Instala las dependencias del laboratorio principal**:
   ```bash
   bundle install
   ```
3. *(Opcional)* **Instala las dependencias del Caso de Estudio 05 (REST API con Sinatra)**:
   ```bash
   cd case_studies/05_rest_api
   bundle install
   cd ../..
   ```
4. **Verifica que el entorno funciona correctamente**:
   ```bash
   bundle exec rake test
   bundle exec rubocop
   ```

---

## Tabla de navegación de módulos y ejemplos

| Módulo | Directorio | Ejemplos ejecutables | Estado |
|---|---|---|---|
| **01. Fundamentos** | [`examples/01_fundamentos/`](examples/01_fundamentos/) | `01_sintaxis_y_convenciones.rb`, `02_variables_y_constantes.rb`, `03_tipos_y_conversiones.rb`, `04_operadores.rb`, `05_strings_simbolos_y_rangos.rb`, `06_nil_y_truthiness.rb`, `07_entrada_y_salida.rb` | Completo |
| **02. Estructuras de datos** | [`examples/02_estructuras_de_datos/`](examples/02_estructuras_de_datos/) | `01_arrays.rb`, `02_hashes.rb`, `03_sets.rb` | Completo |
| **03. Control de flujo** | [`examples/03_control_de_flujo/`](examples/03_control_de_flujo/) | `01_condicionales.rb`, `02_bucles_e_iteradores.rb` | Completo |
| **04. Métodos y bloques** | [`examples/04_metodos_y_bloques/`](examples/04_metodos_y_bloques/) | `01_definicion_y_parametros.rb`, `02_alcance.rb`, `03_bloques_y_yield.rb`, `04_proc_y_lambda.rb`, `05_closures.rb` | Completo |
| **05. Programación funcional** | [`examples/05_programacion_funcional/`](examples/05_programacion_funcional/) | `01_transformaciones.rb`, `02_imperativo_vs_idiomatico.rb`, `03_inmutabilidad.rb`, `04_evaluacion_diferida.rb` | Completo |
| **06. Orientación a objetos** | [`examples/06_programacion_orientada_a_objetos/`](examples/06_programacion_orientada_a_objetos/) | `01_clases_e_instancias.rb`, `02_herencia_y_polimorfismo.rb`, `03_solid_y_patrones.rb` | Completo |
| **07. Módulos y mixins** | [`examples/07_modulos_y_mixins/`](examples/07_modulos_y_mixins/) | `01_modulos_y_mixins.rb` | Completo |
| **08. Excepciones y validación** | [`examples/08_excepciones_y_validacion/`](examples/08_excepciones_y_validacion/) | `01_excepciones.rb` | Completo |
| **09. Archivos y datos** | [`examples/09_archivos_y_datos/`](examples/09_archivos_y_datos/) | `01_archivos_y_persistencia.rb` | Completo |
| **10. Regex y texto** | [`examples/10_regex_y_texto/`](examples/10_regex_y_texto/) | `01_expresiones_regulares.rb` | Completo |
| **11. Algoritmos y estructuras** | [`examples/11_algoritmos_y_estructuras/`](examples/11_algoritmos_y_estructuras/) | `01_busqueda_y_ordenamiento.rb`, `02_estructuras_de_datos.rb` | Completo |
| **12. Enumerables e iteradores** | [`examples/12_enumerables_y_iteradores/`](examples/12_enumerables_y_iteradores/) | `01_enumerable_avanzado.rb` | Completo |
| **13. Concurrencia** | [`examples/13_concurrencia/`](examples/13_concurrencia/) | `01_threads_y_concurrencia.rb` | Completo |
| **14. Recursos avanzados** | [`examples/14_recursos_avanzados/`](examples/14_recursos_avanzados/) | `01_metaprogramacion.rb`, `02_benchmarks_y_profiling.rb`, `03_gemas_y_bundler.rb` | Completo |

---

## Cómo ejecutar los ejemplos

Puedes ejecutar cualquier ejemplo directamente con `ruby` o mediante la CLI del laboratorio `bin/ruby-lab`:

```bash
# Listar todos los ejemplos disponibles (o filtrar por prefijo de módulo)
ruby bin/ruby-lab list
ruby bin/ruby-lab list 05

# Ejecutar un ejemplo por su identificador corto
ruby bin/ruby-lab run 01/03

# O ejecutar el archivo directamente
ruby examples/01_fundamentos/03_tipos_y_conversiones.rb
```

---

## Cómo trabajar con los ejercicios y las soluciones

Los ejercicios están organizados en tres niveles progresivos dentro de [`exercises/`](exercises/) y sus soluciones ejecutables se encuentran separadas en [`solutions/`](solutions/):

```bash
# Listar los 28 ejercicios o filtrar por nivel (beginner, intermediate, advanced)
ruby bin/ruby-lab exercises
ruby bin/ruby-lab exercises beginner

# Ejecutar una solución de referencia directamente para ver su demostración
ruby solutions/beginner/01_temperature_converter.rb

# Ejecutar las pruebas automatizadas de todas las soluciones
bundle exec rake test:solutions
```

Si deseas resolver los ejercicios en tu propia carpeta (por ejemplo `mi_trabajo/beginner/01_temperature_converter.rb`), puedes validar tu implementación usando la misma suite de pruebas:

```bash
RUBY_LAB_SOLUTIONS_DIR=mi_trabajo bundle exec rake test:solutions
```

---

## Casos de estudio completos

Cada caso de estudio en [`case_studies/`](case_studies/) integra varios conceptos del lenguaje en una arquitectura limpia con pruebas automatizadas.

### 1. CLI Expense Tracker (`case_studies/01_cli_expense_tracker/`)
- **Problema**: registrar ingresos y gastos personales, filtrar por fechas/categorías, calcular balances sin errores de redondeo y exportar a CSV.
- **Decisiones de diseño**: importes en centavos (`Integer`), entidades inmutables (`Data.define`), persistencia JSON con escritura atómica (`Tempfile` + `FileUtils.mv`) y separación entre `Transaction`, `Ledger`, `JsonStore`, `CsvExporter` y `CLI`.
- **Conceptos de Ruby**: `Data.define`, `OptionParser`, `JSON`, `CSV`, `Enumerable#each_with_object`.
- **Ejecución**:
  ```bash
  ruby case_studies/01_cli_expense_tracker/bin/expense-tracker summary --storage case_studies/01_cli_expense_tracker/data/sample_expenses.json
  ruby case_studies/01_cli_expense_tracker/bin/expense-tracker list --storage case_studies/01_cli_expense_tracker/data/sample_expenses.json
  ```
- **Ampliación sugerida**: presupuestos mensuales por categoría y soporte multimoneda.

### 2. Inventory Management (`case_studies/02_inventory_management/`)
- **Problema**: gestionar catálogo de productos, entradas y salidas de stock evitando cantidades inválidas o stock negativo, detectar stock bajo y valorar el inventario.
- **Decisiones de diseño**: encapsulamiento de reglas de stock dentro del dominio (`Product`, `StockMovement`, `InventoryService`), desacoplado del repositorio JSON y de la interfaz de consola.
- **Conceptos de Ruby**: clases con invariantes estrictos, jerarquía de excepciones de dominio, búsqueda multicriterio y agregaciones.
- **Ejecución**:
  ```bash
  ruby case_studies/02_inventory_management/bin/inventory report --storage case_studies/02_inventory_management/data/sample_inventory.json
  ruby case_studies/02_inventory_management/bin/inventory low-stock --storage case_studies/02_inventory_management/data/sample_inventory.json
  ```
- **Ampliación sugerida**: lotes con fecha de caducidad (FIFO/FEFO) y valoración por costo promedio ponderado.

### 3. Help Desk Ticketing (`case_studies/03_helpdesk_ticketing/`)
- **Problema**: administrar incidencias de soporte técnico con prioridades, asignación de agentes, historial auditable de cambios y métricas de tiempos de resolución.
- **Decisiones de diseño**: política de transiciones de estado explícita (`TransitionPolicy`) en una capa independiente que impide cambios de estado arbitrarios.
- **Conceptos de Ruby**: máquinas de estado, cálculo temporal con `Time`, estadísticas agrupadas por técnico/prioridad/estado.
- **Ejecución**:
  ```bash
  ruby case_studies/03_helpdesk_ticketing/bin/helpdesk list --storage case_studies/03_helpdesk_ticketing/data/sample_tickets.json
  ruby case_studies/03_helpdesk_ticketing/bin/helpdesk stats --storage case_studies/03_helpdesk_ticketing/data/sample_tickets.json
  ```
- **Ampliación sugerida**: acuerdos de nivel de servicio (SLA) por prioridad y escalado automático.

### 4. Log Analyzer (`case_studies/04_log_analyzer/`)
- **Problema**: procesar archivos de registro potencialmente grandes clasificando severidades, detectando patrones repetidos y tolerando líneas mal formadas sin agotar la memoria.
- **Decisiones de diseño**: lectura perezosa línea a línea (`File.foreach` + `Enumerator::Lazy`), expresiones regulares con capturas nombradas y generador de reportes JSON/CSV.
- **Conceptos de Ruby**: `Regexp` con grupos nombrados, `Enumerator::Lazy`, streaming de E/S y `Benchmark.bm`.
- **Ejecución**:
  ```bash
  ruby case_studies/04_log_analyzer/bin/log-analyzer analyze case_studies/04_log_analyzer/data/sample_app.log
  bundle exec rake benchmark
  ```
- **Ampliación sugerida**: soporte para logs en formato JSON Lines (`.jsonl`) y ventanas móviles de tasa de error.

### 5. REST API (`case_studies/05_rest_api/`)
- **Problema**: exponer un servicio HTTP JSON para administrar tickets con validación de entradas, códigos de estado HTTP semánticos y manejo centralizado de errores.
- **Decisiones de diseño**: microframework **Sinatra** aislado en su propio `Gemfile` para mantener el repositorio raíz libre de dependencias web; separación entre rutas HTTP (`RestApi::App`), servicio (`TicketService`), entidad (`Ticket`) y repositorio (`TicketRepository`).
- **Conceptos de Ruby**: Rack, Sinatra, serialización JSON, variables de entorno (`ENV.fetch`) y pruebas de integración HTTP con `Rack::Test`.
- **Ejecución**:
  ```bash
  cd case_studies/05_rest_api
  bundle install
  bundle exec rackup -p 4567
  ```
- **Ampliación sugerida**: autenticación mediante token Bearer, paginación y adaptador SQLite con consultas parametrizadas.

---

## Pruebas automatizadas y análisis estático

```bash
# Ejecutar toda la suite principal (ejemplos, unitarias, integración, soluciones y casos 01-04)
bundle exec rake test

# Ejecutar un grupo específico de pruebas
bundle exec rake test:examples
bundle exec rake test:unit
bundle exec rake test:integration
bundle exec rake test:solutions
bundle exec rake test:case_studies

# Ejecutar las pruebas de integración del Caso de Estudio 05 (REST API)
bundle exec rake test:api

# Ejecutar el análisis estático de código y estilo con RuboCop
bundle exec rubocop

# Ejecutar los benchmarks reproducibles del analizador de logs
bundle exec rake benchmark
```

---

## Estructura del repositorio

```text
ruby-practical-lab/
├── README.md
├── LICENSE
├── CONTRIBUTING.md
├── CHANGELOG.md
├── Gemfile
├── Gemfile.lock
├── Rakefile
├── .ruby-version
├── .gitignore
├── .rubocop.yml
├── .editorconfig
├── bin/
│   └── ruby-lab
├── lib/
│   ├── ruby_lab.rb
│   └── ruby_lab/
│       ├── version.rb
│       ├── catalog.rb
│       └── cli.rb
├── examples/
│   ├── 01_fundamentos/
│   ├── 02_estructuras_de_datos/
│   ├── 03_control_de_flujo/
│   ├── 04_metodos_y_bloques/
│   ├── 05_programacion_funcional/
│   ├── 06_programacion_orientada_a_objetos/
│   ├── 07_modulos_y_mixins/
│   ├── 08_excepciones_y_validacion/
│   ├── 09_archivos_y_datos/
│   ├── 10_regex_y_texto/
│   ├── 11_algoritmos_y_estructuras/
│   ├── 12_enumerables_y_iteradores/
│   ├── 13_concurrencia/
│   └── 14_recursos_avanzados/
├── exercises/
│   ├── beginner/        (10 ejercicios)
│   ├── intermediate/    (10 ejercicios)
│   └── advanced/        (8 ejercicios)
├── solutions/
│   ├── beginner/        (10 soluciones ejecutables)
│   ├── intermediate/    (10 soluciones ejecutables)
│   └── advanced/        (8 soluciones ejecutables)
├── case_studies/
│   ├── 01_cli_expense_tracker/
│   ├── 02_inventory_management/
│   ├── 03_helpdesk_ticketing/
│   ├── 04_log_analyzer/
│   └── 05_rest_api/
├── docs/
│   ├── learning_path.md
│   ├── ruby_style_guide.md
│   ├── testing_guide.md
│   ├── debugging_guide.md
│   ├── architecture.md
│   ├── common_mistakes.md
│   └── glossary.md
├── test/
│   ├── examples/
│   ├── unit/
│   ├── integration/
│   ├── solutions/
│   └── test_helper.rb
└── .github/
    └── workflows/
        └── ci.yml
```

---

## Documentación técnica adicional (`docs/`)

- [Ruta de aprendizaje recomendada](docs/learning_path.md)
- [Guía de estilo de Ruby](docs/ruby_style_guide.md)
- [Guía de pruebas con Minitest](docs/testing_guide.md)
- [Guía de depuración y diagnóstico](docs/debugging_guide.md)
- [Arquitectura del repositorio](docs/architecture.md)
- [Errores comunes en Ruby y cómo evitarlos](docs/common_mistakes.md)
- [Glosario técnico](docs/glossary.md)

---

## Tecnologías y dependencias justificadas

| Gema | Alcance | Justificación |
|---|---|---|
| `csv` (`~> 3.3`), `logger` (`~> 1.7`), `benchmark` (`~> 0.5`) | `Gemfile` raíz | Librerías oficiales de Ruby que en Ruby 3.4/4.0 pasaron a ser *bundled gems*; deben declararse en `Gemfile` para cargarse bajo Bundler. |
| `minitest` (`~> 6.0`) | Desarrollo y test | Framework de pruebas rápido, expresivo y estándar en el ecosistema Ruby. |
| `rake` (`~> 13.4`) | Desarrollo y test | Automatización de tareas de prueba y benchmarks. |
| `rubocop` (`~> 1.92`), `rubocop-minitest`, `rubocop-rake` | Desarrollo y test | Verificación automática de estilo, convenciones idiomáticas y buenas prácticas en pruebas. |
| `sinatra` (`~> 4.2`), `rackup`, `puma`, `rack-test` | Solo `case_studies/05_rest_api/Gemfile` | Microframework HTTP ligero y su cliente de pruebas para el Caso de Estudio 05 sin acoplar el resto del repositorio. |

---

## Limitaciones conocidas

1. **Persistencia local en archivos JSON**: los repositorios JSON de los casos de estudio utilizan escritura atómica (`Tempfile` + renombrado) para prevenir corrupción por cortes abruptos, pero **no sustituyen a un motor transaccional (como PostgreSQL o SQLite)** ante escrituras concurrentes desde múltiples procesos.
2. **Concurrencia y GVL**: los ejemplos con `Thread` en CRuby están sujetos al *Global VM Lock* (GVL); aceleran operaciones intensivas en E/S pero no paralelizan cálculo puro de CPU en un mismo `Ractor`.

---

## Contribución y Licencia

Consulta [CONTRIBUTING.md](CONTRIBUTING.md) para conocer el flujo de trabajo y los criterios de calidad. Este proyecto se distribuye bajo la licencia [MIT](LICENSE).

