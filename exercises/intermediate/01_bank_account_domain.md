# Dominio de cuenta bancaria con historial inmutable

## Enunciado inequívoco
Implementa el módulo `Solutions::Intermediate::BankAccountDomain` con una clase `Account` que gestione saldos monetarios expresados exclusivamente en centavos enteros (`Integer`), permita depósitos, retiros y transferencias entre cuentas, registre un historial inmutable de movimientos (`Movement`) y lance una excepción de dominio `InsufficientFundsError` cuando no existan fondos suficientes.

## Contexto del problema
En sistemas financieros y de facturación reales, representar dinero mediante números en coma flotante (`Float`) introduce errores de redondeo binarios inaceptables (`0.1 + 0.2 != 0.3`). Además, exponer el saldo mediante un `attr_accessor` o devolver la referencia interna del arreglo de movimientos rompe el encapsulamiento y permite alterar el estado contable sin auditoría. Este ejercicio modela una entidad de dominio robusta aplicando encapsulamiento estricto y objetos de valor inmutables con `Data.define`.

## Requisitos funcionales
1. Definir `InsufficientFundsError < StandardError` dentro de `Solutions::Intermediate::BankAccountDomain`.
2. Definir el objeto de valor inmutable `Movement = Data.define(:kind, :amount_cents, :balance_after_cents, :note)`.
3. Implementar `Account#initialize(owner:, opening_balance_cents: 0)`:
   - Validar que `owner` no esté vacío tras `strip`.
   - Validar que `opening_balance_cents` sea un `Integer` mayor o igual a `0`.
   - Si `opening_balance_cents.positive?`, registrar un movimiento inicial de tipo `:opening` con nota `"Opening balance"`.
4. Implementar `Account#deposit(amount_cents, note: "Deposit")`:
   - Validar que `amount_cents` sea un `Integer` estrictamente positivo (`> 0`).
   - Incrementar `balance_cents`, registrar un `Movement` con `kind: :deposit` y retornar `balance_cents`.
5. Implementar `Account#withdraw(amount_cents, note: "Withdrawal")`:
   - Validar que `amount_cents` sea un `Integer` estrictamente positivo (`> 0`).
   - Si `amount_cents > balance_cents`, lanzar `InsufficientFundsError` sin modificar el estado ni el historial.
   - Reducir `balance_cents`, registrar un `Movement` con `kind: :withdrawal` y retornar `balance_cents`.
6. Implementar `Account#transfer_to(target_account, amount_cents)`:
   - Validar que `target_account` sea una instancia de `Account` distinta de `self` (`ArgumentError` en caso contrario).
   - Retirar de la cuenta origen con nota `"Transfer to #{target_account.owner}"` y depositar en `target_account` con nota `"Transfer from #{owner}"`.
7. Implementar `Account#movements` devolviendo una copia congelada (`.dup.freeze`) para impedir mutaciones externas.

## Restricciones técnicas
- Prohibido usar `Float` para importes; rechazar cualquier cantidad que no sea `Integer` lanzando `ArgumentError`.
- Todos los objetos `Movement` y el arreglo devuelto por `#movements` deben ser inmutables.
- El código debe cumplir con RuboCop sin excepciones.

## Ejemplos de entrada y salida
```ruby
alice = Solutions::Intermediate::BankAccountDomain::Account.new(owner: "Alice", opening_balance_cents: 10_000)
bob = Solutions::Intermediate::BankAccountDomain::Account.new(owner: "Bob")

alice.deposit(2_500, note: "Payroll") # => 12500
alice.transfer_to(bob, 4_000)
alice.balance_cents                   # => 8500
bob.balance_cents                     # => 4000
alice.movements.map(&:kind)           # => [:opening, :deposit, :withdrawal]
```

## Casos límite
- Creación de cuenta con `opening_balance_cents: 0` (no debe generar movimiento `:opening`).
- Intento de depósito o retiro de `0` centavos, números negativos o valores `Float` (`10.5`) debe lanzar `ArgumentError`.
- Intento de transferir a la misma cuenta (`alice.transfer_to(alice, 500)`) debe lanzar `ArgumentError`.
- Intento de mutar el arreglo retornado por `account.movements << ...` debe lanzar `FrozenError`.

## Criterios de aceptación
- `Account` mantiene la invariante: el saldo actual coincide siempre con la suma de depósitos e inicialización menos los retiros.
- Cuando `withdraw` o `transfer_to` falla por falta de fondos, ninguna de las cuentas involucradas sufre alteraciones.
- Todas las pruebas en `test/solutions/intermediate_solutions_test.rb` pasan sin advertencias.

## Sugerencia de implementación
Apóyate en métodos privados de validación (`validate_positive_cents!`, `validate_target!`) y un método privado `record_movement(kind, amount_cents, note)` para mantener cada método público por debajo de 10 líneas.
