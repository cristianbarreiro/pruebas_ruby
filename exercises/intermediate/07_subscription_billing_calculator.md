# Calculadora de prorrateo para facturación de suscripciones

## Enunciado inequívoco
Implementa el módulo `Solutions::Intermediate::SubscriptionBillingCalculator` para calcular cargos o créditos prorrateados en centavos cuando un cliente cambia de plan de suscripción en una fecha determinada del mes (`Date`), considerando meses de 28, 29, 30 y 31 días.

## Contexto del problema
En plataformas SaaS con facturación mensual calendario, cuando un usuario actualiza (`upgrade`) o reduce (`downgrade`) su plan a mitad de mes, se debe calcular cuántos días del mes permaneció en el plan anterior y cuántos días (incluyendo el día del cambio) estará en el nuevo plan. Usar una constante fija de 30 días genera discrepancias contables en febrero (28 o 29 días en año bisiesto) y en meses de 31 días.

## Requisitos funcionales
1. Requerir la biblioteca estándar `"date"`.
2. Definir `PlanChangeQuote = Data.define(:days_in_month, :used_days, :remaining_days, :unused_credit_cents, :new_plan_charge_cents, :net_amount_cents)`.
3. Implementar `SubscriptionBillingCalculator.calculate_change(current_price_cents:, new_price_cents:, billing_month_start:, change_date:)`:
   - Validar que `current_price_cents >= 0` y `new_price_cents >= 0`.
   - Validar que `billing_month_start` sea el día `1` del mes y que `change_date` pertenezca al mismo año y mes que `billing_month_start` (`ArgumentError` en caso contrario).
   - Calcular `days_in_month` usando `Date.new(year, month, -1).day`.
   - Calcular `used_days = change_date.day - 1` y `remaining_days = days_in_month - used_days`.
   - Calcular `unused_credit_cents = (current_price_cents * remaining_days.to_f / days_in_month).round`.
   - Calcular `new_plan_charge_cents = (new_price_cents * remaining_days.to_f / days_in_month).round`.
   - Calcular `net_amount_cents = new_plan_charge_cents - unused_credit_cents` (positivo si el cliente debe pagar diferencia, negativo si recibe saldo a favor).
   - Retornar la instancia de `PlanChangeQuote`.

## Restricciones técnicas
- Usar objetos `Date` de la biblioteca estándar de Ruby.
- Todos los resultados monetarios deben redondearse al centavo entero más cercano (`#round`).

## Ejemplos de entrada y salida
```ruby
require "date"
calc = Solutions::Intermediate::SubscriptionBillingCalculator
quote = calc.calculate_change(
  current_price_cents: 3_000,
  new_price_cents: 6_000,
  billing_month_start: Date.new(2026, 4, 1),
  change_date: Date.new(2026, 4, 16)
)
quote.days_in_month    # => 30
quote.used_days        # => 15
quote.remaining_days   # => 15
quote.net_amount_cents # => 1500
```

## Casos límite
- Cambio el primer día del ciclo (`change_date == billing_month_start`): `used_days == 0`, `remaining_days == days_in_month`, `net_amount_cents == new_price_cents - current_price_cents`.
- Cambio en febrero de año bisiesto (p. ej. `2024-02-01` con 29 días) frente a febrero no bisiesto (`2026-02-01` con 28 días).
- Cambio al mismo precio (`current_price_cents == new_price_cents`): `net_amount_cents == 0`.
- `change_date` fuera del mes de `billing_month_start` debe lanzar `ArgumentError`.

## Criterios de aceptación
- `used_days + remaining_days == days_in_month` para cualquier fecha válida del mes.
- Maneja años bisiestos automáticamente apoyándose en `Date`.

## Sugerencia de implementación
Obtén el último día del mes con `Date.new(billing_month_start.year, billing_month_start.month, -1)` y verifica que `(billing_month_start..month_end).cover?(change_date)`.
