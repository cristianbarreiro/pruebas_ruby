# frozen_string_literal: true

module Solutions
  module Advanced
    module ImmutableQueryBuilder
      OrderRule = Data.define(:field, :direction)
      Pagination = Data.define(:page, :per_page)

      class QueryBuilder
        VALID_DIRECTIONS = %i[asc desc].freeze

        attr_reader :records, :filters, :orders, :pagination

        def initialize(records, filters: [], orders: [], pagination: nil)
          @records = records.map { |row| row.is_a?(Hash) ? row.dup.freeze : row }.freeze
          @filters = filters.dup.freeze
          @orders = orders.dup.freeze
          @pagination = pagination
          freeze
        end

        def where(criteria = {}, &predicate)
          raise ArgumentError, "Debe indicar criterios o un bloque de filtrado" if criteria.empty? && !predicate

          new_filters = @filters.dup
          new_filters << build_hash_filter(criteria) unless criteria.empty?
          new_filters << predicate if predicate
          spawn(filters: new_filters)
        end

        def order_by(field, direction = :asc)
          dir = direction.to_sym
          unless VALID_DIRECTIONS.include?(dir)
            raise ArgumentError, "Dirección inválida: #{direction}. Usa :asc o :desc"
          end

          spawn(orders: @orders + [OrderRule.new(field: field, direction: dir)])
        end

        def paginate(page:, per_page:)
          unless page.is_a?(Integer) && page >= 1 && per_page.is_a?(Integer) && per_page >= 1
            raise ArgumentError, "page y per_page deben ser enteros mayores o iguales a 1"
          end

          spawn(pagination: Pagination.new(page: page, per_page: per_page))
        end

        def execute
          filtered = apply_filters(@records)
          sorted = apply_orders(filtered)
          build_paginated_response(sorted)
        end

        def to_a
          execute[:data]
        end

        private

        def spawn(filters: @filters, orders: @orders, pagination: @pagination)
          self.class.new(@records, filters: filters, orders: orders, pagination: pagination)
        end

        def build_hash_filter(criteria)
          frozen_criteria = criteria.dup.freeze
          ->(row) { frozen_criteria.all? { |field, expected| match_value?(fetch_val(row, field), expected) } }
        end

        def match_value?(actual, expected)
          return expected.include?(actual) if expected.is_a?(Array) || expected.is_a?(Set)

          expected === actual # rubocop:disable Style/CaseEquality
        end

        def fetch_val(row, field)
          return row[field] if row.is_a?(Hash) && row.key?(field)
          return row[field.to_s] if row.is_a?(Hash) && row.key?(field.to_s)

          row.public_send(field) if row.respond_to?(field)
        end

        def apply_filters(rows)
          @filters.reduce(rows) { |acc, filter_proc| acc.select(&filter_proc) }
        end

        def apply_orders(rows)
          return rows if @orders.empty?

          rows.sort { |lhs, rhs| compare_rows(lhs, rhs) }
        end

        def compare_rows(lhs, rhs)
          @orders.each do |rule|
            val_lhs = fetch_val(lhs, rule.field)
            val_rhs = fetch_val(rhs, rule.field)
            cmp = val_lhs <=> val_rhs
            next if cmp.nil? || cmp.zero?

            return rule.direction == :desc ? -cmp : cmp
          end
          0
        end

        def build_paginated_response(rows)
          total = rows.size
          page = @pagination ? @pagination.page : 1
          per_page = @pagination ? @pagination.per_page : [total, 1].max
          total_pages = total.zero? ? 0 : (total.to_f / per_page).ceil
          offset = (page - 1) * per_page
          slice = (rows[offset, per_page] || []).freeze
          { data: slice, meta: { page: page, per_page: per_page, total: total, total_pages: total_pages } }
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  users = [
    { id: 1, name: "Ana", role: "admin", score: 95 },
    { id: 2, name: "Luis", role: "editor", score: 82 },
    { id: 3, name: "Marta", role: "admin", score: 88 },
    { id: 4, name: "Carlos", role: "admin", score: 91 }
  ]

  base_query = Solutions::Advanced::ImmutableQueryBuilder::QueryBuilder.new(users)
  admins_page = base_query.where(role: "admin").order_by(:score, :desc).paginate(page: 1, per_page: 2)

  puts "Resultado paginado de administradores:"
  p admins_page.execute
  puts "Total en consulta base inmutable: #{base_query.execute[:meta][:total]}"
end
