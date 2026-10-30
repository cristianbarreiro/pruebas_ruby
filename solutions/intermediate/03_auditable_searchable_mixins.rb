# frozen_string_literal: true

# = Mixins de auditoría y catálogo iterable con Enumerable y Comparable

module Solutions
  module Intermediate
    module AuditableSearchableMixins
      AuditEvent = Data.define(:action, :detail, :at)

      module Auditable
        def record_audit(action, detail: "")
          audit_events << AuditEvent.new(action: action.to_sym, detail: detail.to_s, at: Time.now.utc)
        end

        def audit_log
          audit_events.dup.freeze
        end

        def last_audit_action
          audit_events.last&.action
        end

        private

        def audit_events
          @audit_events ||= []
        end
      end

      class CatalogItem
        include Comparable
        include Auditable

        attr_reader :sku, :name, :price_cents, :category, :active

        def initialize(sku:, name:, price_cents:, category:, active: true)
          validate_price!(price_cents)
          @sku = sku.to_s
          @name = name.to_s
          @price_cents = price_cents
          @category = category.to_sym
          @active = active
          record_audit(:created, detail: "Initial price #{@price_cents}")
        end

        def active?
          @active
        end

        def update_price(new_price_cents)
          validate_price!(new_price_cents)
          previous = @price_cents
          @price_cents = new_price_cents
          record_audit(:price_updated, detail: "#{previous}->#{new_price_cents}")
          @price_cents
        end

        def deactivate!
          @active = false
          record_audit(:deactivated, detail: @sku)
        end

        def <=>(other)
          return nil unless other.is_a?(CatalogItem)

          [@price_cents, @sku] <=> [other.price_cents, other.sku]
        end

        private

        def validate_price!(price_cents)
          return if price_cents.is_a?(Integer) && price_cents.positive?

          raise ArgumentError, "Price must be positive"
        end
      end

      class CatalogCollection
        include Enumerable

        def initialize(items = [])
          @items = []
          items.each { |item| add(item) }
        end

        def add(item)
          raise ArgumentError, "Expected CatalogItem" unless item.is_a?(CatalogItem)

          @items << item
          self
        end

        def each(&block)
          return enum_for(:each) unless block

          @items.each(&block)
        end

        def by_category(category)
          target = category.to_sym
          select { |item| item.active? && item.category == target }.sort
        end

        def price_range(min_cents:, max_cents:)
          select { |item| item.active? && (min_cents..max_cents).cover?(item.price_cents) }.sort
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  mod = Solutions::Intermediate::AuditableSearchableMixins
  mouse = mod::CatalogItem.new(sku: "A1", name: "Mouse", price_cents: 2_500, category: :peripherals)
  keyboard = mod::CatalogItem.new(sku: "B2", name: "Keyboard", price_cents: 5_000, category: :peripherals)
  mouse.update_price(2_200)
  catalog = mod::CatalogCollection.new([keyboard, mouse])
  puts "Sorted SKUs: #{catalog.by_category(:peripherals).map(&:sku).join(", ")}"
  puts "Mouse last audit: #{mouse.last_audit_action}"
end
