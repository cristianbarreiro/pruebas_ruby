# frozen_string_literal: true

module Solutions
  module Beginner
    # Motor de búsqueda y filtrado componible en memoria para un catálogo de productos.
    module ProductCatalogSearch
      Criteria = Data.define(:query, :category, :min_price, :max_price, :in_stock_only)
      ALLOWED_FILTERS = %i[query category min_price max_price in_stock_only].freeze

      module_function

      def search(products, **filters)
        raise ArgumentError, "El catálogo debe ser un Array" unless products.is_a?(Array)

        criteria = build_criteria(filters)
        products
          .select { |prod| matches_all?(prod, criteria) }
          .sort_by { |prod| [prod[:price], prod[:name].to_s.downcase] }
      end

      def build_criteria(filters)
        unknown = filters.keys - ALLOWED_FILTERS
        raise ArgumentError, "Filtros desconocidos: #{unknown.join(", ")}" unless unknown.empty?

        min_price = filters[:min_price]
        max_price = filters[:max_price]
        validate_price_bounds!(min_price, max_price)

        Criteria.new(
          query: filters[:query],
          category: filters[:category],
          min_price: min_price,
          max_price: max_price,
          in_stock_only: filters.fetch(:in_stock_only, false)
        )
      end
      private_class_method :build_criteria

      def validate_price_bounds!(min_price, max_price)
        validate_non_negative_price!(min_price, "min_price")
        validate_non_negative_price!(max_price, "max_price")
        return unless min_price && max_price && min_price > max_price

        raise ArgumentError, "min_price no puede ser mayor que max_price"
      end
      private_class_method :validate_price_bounds!

      def validate_non_negative_price!(val, label)
        return if val.nil?
        return if val.is_a?(Numeric) && !val.negative?

        raise ArgumentError, "#{label} debe ser un número no negativo"
      end
      private_class_method :validate_non_negative_price!

      def matches_all?(prod, criteria)
        matches_query?(prod, criteria.query) &&
          matches_category?(prod, criteria.category) &&
          matches_price?(prod, criteria.min_price, criteria.max_price) &&
          matches_stock?(prod, criteria.in_stock_only)
      end
      private_class_method :matches_all?

      def matches_query?(prod, query)
        return true if query.nil? || query.to_s.strip.empty?

        prod[:name].to_s.downcase.include?(query.to_s.strip.downcase)
      end
      private_class_method :matches_query?

      def matches_category?(prod, category)
        return true if category.nil? || category.to_s.strip.empty?

        prod[:category].to_s.downcase == category.to_s.strip.downcase
      end
      private_class_method :matches_category?

      def matches_price?(prod, min_price, max_price)
        price = prod[:price]
        return false if min_price && price < min_price
        return false if max_price && price > max_price

        true
      end
      private_class_method :matches_price?

      def matches_stock?(prod, in_stock_only)
        return true unless in_stock_only

        prod[:stock].to_i.positive?
      end
      private_class_method :matches_stock?
    end
  end
end

if $PROGRAM_NAME == __FILE__
  catalog = [
    { name: "Monitor 27\"", category: "electronics", price: 250.0, stock: 5 },
    { name: "Mouse Inalámbrico", category: "electronics", price: 25.0, stock: 0 },
    { name: "Teclado Mecánico", category: "electronics", price: 80.0, stock: 12 }
  ]
  results = Solutions::Beginner::ProductCatalogSearch.search(catalog, category: :electronics, in_stock_only: true)
  puts results.inspect
end
