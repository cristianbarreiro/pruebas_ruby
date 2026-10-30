# Jerarquía de excepciones y reintentos en pasarela de pagos

## Enunciado inequívoco
Implementa el módulo `Solutions::Intermediate::PaymentGatewayErrors` con una jerarquía de excepciones de dominio (`PaymentError`, `TransientGatewayError`, `InvalidCardError`) y un procesador `PaymentProcessor` que reintente únicamente los fallos transitorios hasta un máximo configurable de reintentos y propague de inmediato los errores permanentes.

## Contexto del problema
Al integrar servicios externos como pasarelas de pago, capturar `Exception` o `StandardError` de forma indiscriminada para reintentar operaciones es un antipatrón grave: reintentar una tarjeta inválida es inútil y puede bloquear la cuenta del cliente, mientras que un timeout de red (`TransientGatewayError`) sí suele resolverse en el siguiente intento.

## Requisitos funcionales
1. Definir la jerarquía de excepciones dentro del módulo:
   - `PaymentError < StandardError`
   - `TransientGatewayError < PaymentError`
   - `InvalidCardError < PaymentError`
2. Definir `ChargeResult = Data.define(:transaction_id, :amount_cents, :attempts)`.
3. Implementar `PaymentProcessor`:
   - `#initialize(gateway:, max_retries: 2)` validando que `max_retries` sea un entero `>= 0`.
   - `#charge(card_token:, amount_cents:)`:
     - Validar que `card_token` no esté vacío y `amount_cents` sea un entero `> 0` (`ArgumentError`).
     - Invocar `gateway.process(card_token: card_token, amount_cents: amount_cents)`.
     - Si el gateway lanza `TransientGatewayError` y el número de reintentos realizados es menor que `max_retries`, volver a intentar la operación.
     - Si se agotan los reintentos para `TransientGatewayError`, relanzar la última excepción `TransientGatewayError`.
     - Si el gateway lanza `InvalidCardError` (o cualquier otro error no transitorio), propagarlo inmediatamente sin reintentar.
     - Cuando `gateway.process` retorna un `transaction_id`, devolver `ChargeResult.new(transaction_id:, amount_cents:, attempts:)`.

## Restricciones técnicas
- Prohibido usar `rescue Exception`.
- `rescue TransientGatewayError` debe ser específico para no interceptar `InvalidCardError`.
- No usar `sleep` real en la ejecución por defecto para mantener las pruebas instantáneas y deterministas.

## Ejemplos de entrada y salida
```ruby
mod = Solutions::Intermediate::PaymentGatewayErrors
attempts = 0
flaky_gateway = Object.new
flaky_gateway.define_singleton_method(:process) do |card_token:, amount_cents:|
  attempts += 1
  raise mod::TransientGatewayError, "Timeout" if attempts < 3

  "tx_99"
end

processor = mod::PaymentProcessor.new(gateway: flaky_gateway, max_retries: 3)
processor.charge(card_token: "tok_visa", amount_cents: 1_500)
# => #<data ChargeResult transaction_id="tx_99", amount_cents=1500, attempts=3>
```

## Casos límite
- `max_retries: 0`: el procesador ejecuta exactamente 1 intento y si falla con `TransientGatewayError`, relanza el error de inmediato.
- Fallo con `InvalidCardError` en el primer intento con `max_retries: 5`: el gateway debe haber sido invocado exactamente 1 vez.
- Importes `<= 0` o `card_token` vacío lanzan `ArgumentError` antes de invocar al gateway.

## Criterios de aceptación
- La jerarquía cumple `TransientGatewayError < PaymentError` e `InvalidCardError < PaymentError`.
- El contador `attempts` en `ChargeResult` refleja el número total de llamadas hechas al gateway hasta lograr el cobro.

## Sugerencia de implementación
Utiliza la palabra clave `retry` de Ruby dentro de un bloque `begin ... rescue TransientGatewayError => err` incrementando un contador local `attempts`.
