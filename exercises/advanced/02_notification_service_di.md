# Servicio de notificaciones con inyección de dependencias

## Enunciado inequívoco
Implementa en `Solutions::Advanced::NotificationServiceDi` un despachador de notificaciones (`NotificationDispatcher`) desacoplado mediante inyección de dependencias (`channels:`, `clock:`, `logger:`) que soporte canal de respaldo (*fallback*) ante fallos de envío y limitación de tasa (*rate limiting*) por destinatario.

## Contexto del problema
Los servicios de notificaciones que instancian directamente clientes de correo, SMS, relojes del sistema (`Time.now`) y loggers globales son difíciles de probar de forma determinista y frágiles ante caídas de proveedores externos. Inyectar los canales, el reloj y el registrador de eventos permite verificar ventanas de limitación de tasa sin usar `sleep` y conmutar automáticamente a un canal secundario cuando el primario falla.

## Requisitos funcionales
1. Definir `NotificationDispatcher` dentro de `Solutions::Advanced::NotificationServiceDi`.
2. El constructor `NotificationDispatcher.new(channels:, clock:, logger:, rate_limit: 3, window_seconds: 60)` recibe:
   - `channels`: hash de `{ nombre_canal_simbolo => objeto_canal }` donde cada canal responde a `#deliver(recipient:, message:)`.
   - `clock`: objeto que responde a `#now` o `#call` devolviendo un instante convertible a `Float` (`#to_f`).
   - `logger`: objeto que responde a `#info(msg)`, `#warn(msg)` y `#error(msg)`.
   - `rate_limit`: máximo de envíos permitidos por destinatario dentro de `window_seconds`.
3. `#dispatch(recipient:, message:, channel:, fallback: nil)`:
   - Valida que `recipient` y `message` no estén vacíos y que `channel` exista en `channels` (lanza `ArgumentError` en caso contrario).
   - Verifica el límite de tasa del destinatario descartando envíos anteriores a `now - window_seconds`. Si ya alcanzó `rate_limit`, registra una advertencia en `logger` y lanza `RateLimitExceededError`.
   - Intenta enviar mediante el canal primario. Si el canal lanza `StandardError` o devuelve `false`, registra una advertencia en `logger` e intenta enviar por el canal `fallback` (si fue especificado y existe).
   - Si el envío tiene éxito (por canal primario o de respaldo), registra el instante de envío para el destinatario, escribe en `logger.info` y devuelve `{ status: :delivered, recipient:, channel: canal_usado, fallback_used: booleano, timestamp: now }`.
   - Si el canal primario falla y no hay `fallback` (o el `fallback` también falla), escribe en `logger.error` y lanza `DeliveryError`.

## Restricciones técnicas
- Prohibido acoplar `NotificationDispatcher` a `Time.now` o `$stdout` directamente dentro de la lógica de despacho; todo acceso temporal o de registro debe pasar por `clock` y `logger`.
- Incluir dobles/implementaciones ligeras (`MemoryChannel`, `FailingChannel`, `FakeClock`, `MemoryLogger`) dentro del módulo para facilitar demostraciones y pruebas.

## Ejemplos de entrada y salida
```ruby
clock = Solutions::Advanced::NotificationServiceDi::FakeClock.new(1_700_000_000.0)
logger = Solutions::Advanced::NotificationServiceDi::MemoryLogger.new
channels = {
  email: Solutions::Advanced::NotificationServiceDi::FailingChannel.new("SMTP caído"),
  sms: Solutions::Advanced::NotificationServiceDi::MemoryChannel.new(:sms)
}

dispatcher = Solutions::Advanced::NotificationServiceDi::NotificationDispatcher.new(
  channels: channels, clock: clock, logger: logger, rate_limit: 2, window_seconds: 60
)

dispatcher.dispatch(recipient: "ana@example.com", message: "Código 1234", channel: :email, fallback: :sms)
# => { status: :delivered, recipient: "ana@example.com", channel: :sms, fallback_used: true, timestamp: 1700000000.0 }
```

## Casos límite
- El límite de tasa se evalúa por destinatario: bloquear a `"ana@example.com"` no afecta a `"luis@example.com"`.
- Cuando el reloj avanza más allá de `window_seconds`, la ventana se desliza y el destinatario puede volver a recibir notificaciones.
- Un intento fallido (cuando tanto el canal primario como el de respaldo fallan) no debe consumir cupo del límite de tasa del destinatario.

## Criterios de aceptación
- Conmutación automática al canal `fallback` cuando el canal primario lanza excepción o devuelve `false`.
- Lanzamiento de `DeliveryError` cuando todos los canales configurados para el envío fallan.
- Lanzamiento de `RateLimitExceededError` al superar `rate_limit` dentro de la ventana activa.

## Sugerencia de implementación
Mantén un hash `@history = Hash.new { |hash, key| hash[key] = [] }` que almacene las marcas de tiempo exitosas por destinatario y pódalo al inicio de cada despacho con `timestamps.reject! { |ts| now - ts >= @window_seconds }`.
