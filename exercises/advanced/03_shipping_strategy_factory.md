# Estrategia, fábrica y repositorio de envíos (Shipping Strategy & Factory)

## Enunciado inequívoco
Implementa en `Solutions::Advanced::ShippingStrategyFactory` un sistema de cotización logística que combine el patrón **Strategy** (`StandardShipping`, `ExpressShipping`, `InternationalShipping`), el patrón **Factory** (`ShippingFactory.for(code)`) y el patrón **Repository** (`ShipmentRepository`) para almacenar y consultar cotizaciones.

## Contexto del problema
El cálculo de tarifas de envío suele degenerar en condicionales extensos según el tipo de servicio (estándar, exprés, internacional), mezclando fórmulas matemáticas, tiempos estimados de entrega, validaciones de peso y persistencia de cotizaciones en una sola clase monolítica. Separar cada algoritmo de cálculo en una estrategia independiente, centralizar su instanciación en una fábrica y aislar el almacenamiento en un repositorio permite añadir nuevos métodos de envío respetando el principio Abierto/Cerrado (OCP).

## Requisitos funcionales
1. Definir dentro de `Solutions::Advanced::ShippingStrategyFactory` el objeto de valor inmutable `Quote = Data.define(:id, :strategy_code, :cost, :estimated_days)` y las tres estrategias:
   - `StandardShipping` (`code: :standard`):
     - Costo: tarifa base `5.0` + `weight_kg * 1.25` + `distance_km * 0.05` (redondeado a 2 decimales).
     - Días estimados: `3 + (distance_km / 500.0).ceil`.
   - `ExpressShipping` (`code: :express`):
     - Peso máximo permitido: `50.0` kg (si `weight_kg > 50`, lanza `ArgumentError`).
     - Costo: tarifa base `15.0` + `weight_kg * 2.50` + `distance_km * 0.12` + recargo de `10.0` si `weight_kg > 20.0` (redondeado a 2 decimales).
     - Días estimados: `[1, (distance_km / 1000.0).ceil].max`.
   - `InternationalShipping` (`code: :international`):
     - Costo: tarifa base `35.0` + `weight_kg * 4.00` + `distance_km * 0.08` + arancel aduanero `declared_value * customs_rate` (por defecto `declared_value: 0.0`, `customs_rate: 0.15`, redondeado a 2 decimales).
     - Días estimados: `7 + (distance_km / 1500.0).ceil`.
2. Todas las estrategias deben validar que `weight_kg > 0` y `distance_km >= 0`, lanzando `ArgumentError` si no se cumple.
3. `ShippingFactory.for(code)` acepta un símbolo o cadena (`:standard`, `"EXPRESS"`, etc.) y devuelve una instancia de la estrategia correspondiente, o lanza `ArgumentError` si el código es desconocido.
4. `ShipmentRepository` gestiona objetos `Quote` en memoria:
   - `#save(quote)` almacena y devuelve la cotización.
   - `#find(quote_id)` recupera una cotización por su identificador o `nil`.
   - `#all` devuelve un arreglo con todas las cotizaciones sin exponer la estructura interna mutable.
   - `#by_strategy(code)` filtra las cotizaciones cuyo `strategy_code` coincida con el código normalizado.
   - `#total_cost` devuelve la suma redondeada a 2 decimales de los costos de todas las cotizaciones guardadas.

## Restricciones técnicas
- Uso de `Data.define` para representar las cotizaciones inmutables.
- Prohibido usar `case`/`if` sobre el código de estrategia fuera de un mapa de registro en `ShippingFactory`.

## Ejemplos de entrada y salida
```ruby
strategy = Solutions::Advanced::ShippingStrategyFactory::ShippingFactory.for(:express)
quote = strategy.build_quote(id: "SHP-01", weight_kg: 10.0, distance_km: 800.0)
# => #<data Quote id="SHP-01", strategy_code=:express, cost=136.0, estimated_days=1>

repo = Solutions::Advanced::ShippingStrategyFactory::ShipmentRepository.new
repo.save(quote)
repo.total_cost # => 136.0
```

## Casos límite
- `distance_km` igual a `0`: válido para entregas en el mismo punto logístico.
- `weight_kg <= 0` o `distance_km < 0`: lanza `ArgumentError`.
- `ExpressShipping` con `weight_kg` superior a `50`: lanza `ArgumentError`.
- Modificar el arreglo devuelto por `repo.all` no debe alterar el contenido interno del repositorio.

## Criterios de aceptación
- `ShippingFactory.for` resuelve nombres en mayúsculas, minúsculas o símbolos y falla con `ArgumentError` ante códigos inválidos.
- Las tres estrategias calculan costos y tiempos de entrega exactos según las fórmulas especificadas.
- `ShipmentRepository` preserva la encapsulación de su colección interna.

## Sugerencia de implementación
Crea un módulo o clase base `BaseShipping` con el método plantilla `#build_quote(id:, weight_kg:, distance_km:, **opts)` que valide los parámetros comunes y delegue `#calculate_cost` y `#estimated_days` a cada estrategia concreta.
