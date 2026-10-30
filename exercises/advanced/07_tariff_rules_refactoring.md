# Refactorización de tarifas eléctricas con motor de reglas (Rule Engine)

## Enunciado inequívoco
Implementa en `Solutions::Advanced::TariffRulesRefactoring` un motor de facturación eléctrica basado en objetos regla conectables (`TariffEngine` + reglas de tarifa base residencial, comercial, recargo por hora punta, descuento por energía verde y tarifa social) que reemplace condicionales anidados por una evaluación declarativa con desglose detallado de cargos.

## Contexto del problema
En sistemas de facturación de servicios públicos, las tarifas evolucionan constantemente por regulaciones gubernamentales: tramos escalonados residenciales, cargos fijos comerciales, penalizaciones por consumo en horario punta y bonificaciones ambientales o sociales. Implementar todas las combinaciones mediante `if/elsif/else` anidados produce métodos con alta complejidad ciclomática difíciles de auditar y mantener.

## Requisitos funcionales
1. Definir dentro de `Solutions::Advanced::TariffRulesRefactoring` el contexto inmutable `ConsumptionContext = Data.define(:customer_type, :kwh, :peak_ratio, :green_certified, :social_tariff)` y el motor `TariffEngine`.
2. Validaciones del contexto (lanzan `ArgumentError` si fallan):
   - `customer_type` debe ser `:residential` o `:commercial`.
   - `kwh` debe ser numérico y `>= 0`.
   - `peak_ratio` debe estar en el rango `0.0..1.0`.
3. Implementar las siguientes reglas conectables (cada una con `#code`, `#applies?(context)` y `#apply(context, current_subtotal)`):
   - `ResidentialBaseRule` (`:residential_base`): aplica si `customer_type == :residential`. Cobra los primeros `200` kWh a `0.12` por kWh y el excedente sobre `200` kWh a `0.18` por kWh.
   - `CommercialBaseRule` (`:commercial_base`): aplica si `customer_type == :commercial`. Cobra `0.22` por kWh más un cargo fijo por demanda de `25.0` cuando `kwh > 0` (`0.0` si `kwh == 0`).
   - `PeakHourSurchargeRule` (`:peak_surcharge`): aplica si `peak_ratio > 0.3` y `kwh > 0`. Añade un recargo de `kwh * peak_ratio * 0.06`.
   - `GreenEnergyDiscountRule` (`:green_discount`): aplica si `green_certified` es verdadero y el subtotal acumulado es mayor que `0`. Descuenta el `10%` del subtotal actual (`-current_subtotal * 0.10`).
   - `SocialTariffDiscountRule` (`:social_discount`): aplica si `customer_type == :residential`, `social_tariff` es verdadero, `kwh <= 250` y el subtotal actual es mayor que `0`. Descuenta el `25%` del subtotal actual (`-current_subtotal * 0.25`).
4. `TariffEngine#calculate(input)` acepta un `ConsumptionContext` o un hash de atributos, evalúa las reglas en orden y devuelve:
   `{ customer_type:, kwh:, total:, breakdown: [{ rule: :codigo, amount: float_redondeado }, ...] }`.

## Restricciones técnicas
- Cada regla debe ser una clase pequeña e independiente que no conozca la implementación interna de las demás reglas.
- `TariffEngine.new(rules: TariffEngine.default_rules)` debe permitir inyectar listas personalizadas de reglas.

## Ejemplos de entrada y salida
```ruby
engine = Solutions::Advanced::TariffRulesRefactoring::TariffEngine.new
bill = engine.calculate(
  customer_type: :residential,
  kwh: 300,
  peak_ratio: 0.5,
  green_certified: true,
  social_tariff: false
)
# Base residencial: 200 * 0.12 + 100 * 0.18 = 42.0
# Recargo punta: 300 * 0.5 * 0.06 = 9.0 (subtotal = 51.0)
# Descuento verde: -10% de 51.0 = -5.1
# => {
#   customer_type: :residential,
#   kwh: 300,
#   total: 45.9,
#   breakdown: [
#     { rule: :residential_base, amount: 42.0 },
#     { rule: :peak_surcharge, amount: 9.0 },
#     { rule: :green_discount, amount: -5.1 }
#   ]
# }
```

## Casos límite
- Consumo `kwh: 0`: el total es `0.0` tanto en residencial como en comercial, sin aplicar recargos ni descuentos vacíos.
- Cliente residencial con `social_tariff: true` pero consumo `kwh: 260` (`> 250`): pierde el beneficio de tarifa social.
- `peak_ratio` exactamente `0.3`: no activa el recargo por hora punta (solo se activa cuando `peak_ratio > 0.3`).

## Criterios de aceptación
- El motor produce el mismo cálculo financiero reemplazando condicionales por evaluación polimórfica de reglas.
- Es posible instanciar `TariffEngine` con un subconjunto o extensión de reglas personalizadas.
- El desglose (`:breakdown`) incluye únicamente las reglas que efectivamente se aplicaron.

## Sugerencia de implementación
Mantén en `TariffEngine#calculate` un acumulador `subtotal` en punto flotante que se actualiza con cada regla aplicable y redondea a 2 decimales tanto cada partida del `:breakdown` como el `:total` final.
