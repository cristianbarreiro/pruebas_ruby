# Pipeline de middlewares inmutable con cortocircuito

## Enunciado inequívoco
Implementa en `Solutions::Advanced::MiddlewarePipeline` una tubería modular de middlewares (`Pipeline#use`, `Pipeline#call(context)`) donde cada paso recibe y devuelve un contexto inmutable (`Context`) pudiendo enriquecer metadatos, validar la solicitud, generar la respuesta o detener la ejecución tempranamente (*short-circuit* / `halt!`).

## Contexto del problema
El procesamiento de peticiones HTTP, comandos de dominio o eventos de mensajería suele requerir pasos transversales ordenados: autenticación, validación de esquema, enriquecimiento de trazabilidad y ejecución del manejador de negocio. Cuando estos pasos se acoplan en un único método o mutan un hash global compartido sin control, resulta difícil reordenar etapas, reutilizar filtros o garantizar que una petición no autorizada detenga de inmediato los pasos subsiguientes.

## Requisitos funcionales
1. Definir `Context = Data.define(:request, :metadata, :response, :halted, :error, :trace)` dentro de `Solutions::Advanced::MiddlewarePipeline` con métodos auxiliares inmutables:
   - `Context.build(request = {})`: inicializa `metadata: {}`, `response: nil`, `halted: false`, `error: nil`, `trace: []` (todos congelados).
   - `#with_meta(**pairs)`: devuelve un nuevo `Context` fusionando los metadatos indicados.
   - `#with_response(resp)`: devuelve un nuevo `Context` asignando `response`.
   - `#add_trace(step_name)`: devuelve un nuevo `Context` añadiendo `step_name` a `trace`.
   - `#halt!(message, status: 400)`: devuelve un nuevo `Context` con `halted: true`, `error: message` y `response: { status: status, error: message }`.
   - `#halted?`: devuelve `true` si el contexto fue detenido.
2. Definir `Pipeline` con:
   - `#use(middleware = nil, &block)`: registra un paso (objeto que responde a `#call(context)` o bloque) y devuelve `self` para permitir encadenamiento. Lanza `ArgumentError` si no se entrega ni objeto ni bloque.
   - `#call(input)`: convierte `input` en `Context` si es un `Hash`, ejecuta los pasos en orden pasando el `Context` resultante al siguiente paso, e interrumpe la ejecución en cuanto `context.halted?` sea verdadero.
3. Incluir cuatro middlewares listos para usar:
   - `AuthMiddleware`: verifica que `context.request[:token]` esté en los tokens válidos; si no, detiene con `status: 401` y `"Unauthorized"`. Si es válido, añade `user_id` a `metadata` y `"auth"` a `trace`.
   - `ValidationMiddleware`: verifica que las claves requeridas existan y no estén vacías en `context.request[:payload]`; si falta alguna, detiene con `status: 422`. Si pasa, añade `"validation"` a `trace`.
   - `EnrichmentMiddleware`: añade `:request_id` a `metadata` y `"enrichment"` a `trace`.
   - `HandlerMiddleware`: construye `{ status: 200, data: ... }` en `response` y añade `"handler"` a `trace`.

## Restricciones técnicas
- El objeto `Context` debe ser completamente inmutable; cada transformación produce una nueva instancia mediante `Data#with`.
- Cuando un middleware invoca `context.halt!`, ningún middleware posterior de la tubería debe ejecutarse.

## Ejemplos de entrada y salida
```ruby
pipeline = Solutions::Advanced::MiddlewarePipeline::Pipeline.new
  .use(Solutions::Advanced::MiddlewarePipeline::AuthMiddleware.new("secret-token" => "usr-1"))
  .use(Solutions::Advanced::MiddlewarePipeline::ValidationMiddleware.new(%i[item quantity]))
  .use(Solutions::Advanced::MiddlewarePipeline::EnrichmentMiddleware.new(request_id: "req-99"))
  .use(Solutions::Advanced::MiddlewarePipeline::HandlerMiddleware.new)

ok_ctx = pipeline.call(token: "secret-token", payload: { item: "Teclado", quantity: 2 })
ok_ctx.response[:status] # => 200
ok_ctx.trace             # => ["auth", "validation", "enrichment", "handler"]

halted_ctx = pipeline.call(token: "invalid", payload: { item: "Teclado", quantity: 2 })
halted_ctx.halted?           # => true
halted_ctx.response[:status] # => 401
halted_ctx.trace             # => ["auth"]
```

## Casos límite
- Pipeline vacío (sin middlewares registrados): `#call` devuelve el `Context` inicial sin errores.
- Middleware definido como bloque inline (`pipeline.use { |ctx| ctx.add_trace("custom") }`).
- Cortocircuito en el primer o segundo paso: `trace` refleja únicamente los pasos alcanzados hasta el corte.

## Criterios de aceptación
- `Context` mantiene inmutabilidad estricta en `request`, `metadata` y `trace`.
- El cortocircuito (`halt!`) impide la ejecución de los pasos restantes.
- `Pipeline#use` soporta tanto objetos con `#call` como bloques y rechaza llamadas sin argumentos con `ArgumentError`.

## Sugerencia de implementación
Utiliza `Enum#reduce` sobre `@steps` dentro de `Pipeline#call` y retorna inmediatamente el acumulador `ctx` en cada iteración si `ctx.halted?` es verdadero (`break ctx if ctx.halted?`).
