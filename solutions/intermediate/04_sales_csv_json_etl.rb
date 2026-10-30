# frozen_string_literal: true

# = Pipeline ETL de ventas de CSV a JSON

require "csv"
require "json"

module Solutions
  module Intermediate
    module SalesCsvJsonEtl
      VALID_STATUSES = %w[paid pending refunded].freeze

      RowError = Data.define(:row_number, :raw_id, :reason)
      ParsedRow = Data.define(:id, :customer, :amount_cents, :status)
      EtlReport = Data.define(
        :total_rows,
        :valid_paid_rows,
        :skipped_unpaid_rows,
        :totals_by_customer,
        :grand_total_cents,
        :errors
      )

      module_function

      def process_csv(csv_text)
        state = initial_state
        CSV.parse(csv_text.to_s.strip, headers: true).each_with_index do |row, idx|
          process_single_row(row, idx + 2, state)
        end
        build_report(state)
      end

      def export_json(csv_text)
        report = process_csv(csv_text)
        JSON.generate(
          total_rows: report.total_rows,
          valid_paid_rows: report.valid_paid_rows,
          skipped_unpaid_rows: report.skipped_unpaid_rows,
          totals_by_customer: report.totals_by_customer,
          grand_total_cents: report.grand_total_cents,
          errors: report.errors.map(&:to_h)
        )
      end

      def initial_state
        { total: 0, paid: 0, skipped: 0, totals: Hash.new(0), errors: [] }
      end

      def process_single_row(row, row_num, state)
        state[:total] += 1
        result = validate_row(row, row_num)
        if result.is_a?(RowError)
          state[:errors] << result
        elsif result.status == "paid"
          state[:paid] += 1
          state[:totals][result.customer] += result.amount_cents
        else
          state[:skipped] += 1
        end
      end

      def validate_row(row, row_num)
        raw_id = row["id"].to_s.strip
        customer = row["customer"].to_s.strip
        status = row["status"].to_s.strip
        return RowError.new(row_num, raw_id, "Missing id or customer") if raw_id.empty? || customer.empty?
        return RowError.new(row_num, raw_id, "Unknown status: #{status}") unless VALID_STATUSES.include?(status)

        amount = parse_positive_cents(row["amount_cents"])
        return RowError.new(row_num, raw_id, "Invalid amount_cents") unless amount

        ParsedRow.new(raw_id, customer, amount, status)
      end

      def parse_positive_cents(raw_amount)
        val = Integer(raw_amount.to_s.strip, 10)
        val.positive? ? val : nil
      rescue ArgumentError
        nil
      end

      def build_report(state)
        totals = state[:totals].freeze
        EtlReport.new(
          total_rows: state[:total],
          valid_paid_rows: state[:paid],
          skipped_unpaid_rows: state[:skipped],
          totals_by_customer: totals,
          grand_total_cents: totals.values.sum,
          errors: state[:errors].freeze
        )
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  sample_csv = <<~CSV
    id,customer,amount_cents,status
    1,Acme,5000,paid
    2,Globex,3000,pending
    3,Acme,invalid,paid
    4,Acme,2500,paid
  CSV
  puts Solutions::Intermediate::SalesCsvJsonEtl.export_json(sample_csv)
end
