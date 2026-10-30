# frozen_string_literal: true

# = Dominio de cuenta bancaria con historial inmutable

module Solutions
  module Intermediate
    module BankAccountDomain
      class InsufficientFundsError < StandardError; end

      Movement = Data.define(:kind, :amount_cents, :balance_after_cents, :note)

      class Account
        attr_reader :owner, :balance_cents

        def initialize(owner:, opening_balance_cents: 0)
          validate_owner!(owner)
          validate_non_negative_cents!(opening_balance_cents)
          @owner = owner.strip
          @balance_cents = opening_balance_cents
          @movements = []
          record_movement(:opening, opening_balance_cents, "Opening balance") if opening_balance_cents.positive?
        end

        def deposit(amount_cents, note: "Deposit")
          validate_positive_cents!(amount_cents)
          @balance_cents += amount_cents
          record_movement(:deposit, amount_cents, note)
          @balance_cents
        end

        def withdraw(amount_cents, note: "Withdrawal")
          validate_positive_cents!(amount_cents)
          ensure_sufficient_funds!(amount_cents)
          @balance_cents -= amount_cents
          record_movement(:withdrawal, amount_cents, note)
          @balance_cents
        end

        def transfer_to(target_account, amount_cents)
          validate_target!(target_account)
          withdraw(amount_cents, note: "Transfer to #{target_account.owner}")
          target_account.deposit(amount_cents, note: "Transfer from #{@owner}")
        end

        def movements
          @movements.dup.freeze
        end

        private

        def record_movement(kind, amount_cents, note)
          @movements << Movement.new(
            kind: kind,
            amount_cents: amount_cents,
            balance_after_cents: @balance_cents,
            note: note
          )
        end

        def validate_owner!(owner)
          return if owner.is_a?(String) && !owner.strip.empty?

          raise ArgumentError, "Owner must be a non-empty String"
        end

        def validate_non_negative_cents!(amount_cents)
          return if amount_cents.is_a?(Integer) && amount_cents >= 0

          raise ArgumentError, "Amount must be a non-negative Integer in cents"
        end

        def validate_positive_cents!(amount_cents)
          return if amount_cents.is_a?(Integer) && amount_cents.positive?

          raise ArgumentError, "Amount must be a positive Integer in cents"
        end

        def ensure_sufficient_funds!(amount_cents)
          return if amount_cents <= @balance_cents

          raise InsufficientFundsError, "Insufficient funds: need #{amount_cents}, have #{@balance_cents}"
        end

        def validate_target!(target_account)
          return if target_account.is_a?(Account) && !target_account.equal?(self)

          raise ArgumentError, "Target must be a different Account instance"
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  domain = Solutions::Intermediate::BankAccountDomain
  alice = domain::Account.new(owner: "Alice", opening_balance_cents: 10_000)
  bob = domain::Account.new(owner: "Bob")
  alice.deposit(2_500, note: "Payroll")
  alice.transfer_to(bob, 4_000)
  puts "Alice balance: #{alice.balance_cents} cents (#{alice.movements.size} movements)"
  puts "Bob balance: #{bob.balance_cents} cents (#{bob.movements.size} movements)"
end
