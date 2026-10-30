# frozen_string_literal: true

require_relative "errors"
require_relative "inventory_service"
require_relative "json_repository"

module InventoryManagement
  # Interfaz de línea de comandos con flujos de entrada/salida inyectables.
  class CLI
    DEFAULT_DB = File.expand_path("../../data/sample_inventory.json", __dir__)

    COMMAND_HANDLERS = {
      "add" => :handle_add,
      "stock-in" => :handle_stock_in,
      "stock-out" => :handle_stock_out,
      "search" => :handle_search,
      "low-stock" => :handle_low_stock,
      "report" => :handle_report,
      "delete" => :handle_delete
    }.freeze

    attr_reader :input, :output

    def initialize(input: $stdin, output: $stdout, service: nil, db_path: DEFAULT_DB)
      @input = input
      @output = output
      @default_service = service
      @default_db_path = db_path
    end

    def run(argv)
      args, db_override = extract_db_flag(argv.dup)
      cmd = args.shift
      return print_help(0) if cmd.nil? || %w[-h --help help].include?(cmd)

      dispatch(cmd, args, resolve_service(db_override))
      0
    rescue Errors::Error, ArgumentError => e
      @output.puts("Error: #{e.message}")
      1
    end

    private

    def dispatch(cmd, args, service)
      handler = COMMAND_HANDLERS[cmd]
      raise ArgumentError, "Comando desconocido: #{cmd}" unless handler

      send(handler, args, service)
    end

    def resolve_service(db_override)
      return @default_service if @default_service && db_override.nil?

      repo = JsonRepository.new(db_override || @default_db_path)
      InventoryService.new(repository: repo)
    end

    def extract_db_flag(args)
      db_path = nil
      cleaned = []
      while (arg = args.shift)
        if arg.start_with?("--db=")
          db_path = arg.split("=", 2).last
        elsif arg == "--db"
          db_path = args.shift
        else
          cleaned << arg
        end
      end
      [cleaned, db_path]
    end

    def handle_add(args, service)
      require_arg_count!(args, 4, "Uso: add SKU NOMBRE CATEGORIA PRECIO_CENTAVOS [STOCK] [MIN_STOCK]")
      prod = service.create_product(
        sku: args[0], name: args[1], category: args[2],
        price_cents: Integer(args[3]), stock: Integer(args[4] || 0), min_stock: Integer(args[5] || 0)
      )
      @output.puts("Producto creado: #{format_product(prod)}")
    end

    def handle_stock_in(args, service)
      require_arg_count!(args, 3, "Uso: stock-in SKU CANTIDAD MOTIVO")
      mov = service.record_entry(sku: args[0], quantity: Integer(args[1]), reason: args[2..].join(" "))
      prod = service.find_product(mov.sku)
      @output.puts("Entrada registrada (+#{mov.quantity}) en #{prod.sku}. Stock actual: #{prod.stock}")
    end

    def handle_stock_out(args, service)
      require_arg_count!(args, 3, "Uso: stock-out SKU CANTIDAD MOTIVO")
      mov = service.record_exit(sku: args[0], quantity: Integer(args[1]), reason: args[2..].join(" "))
      prod = service.find_product(mov.sku)
      @output.puts("Salida registrada (-#{mov.quantity}) en #{prod.sku}. Stock actual: #{prod.stock}")
    end

    def handle_search(args, service)
      items = service.search(args.join(" "))
      return @output.puts("Sin resultados.") if items.empty?

      items.each { |prod| @output.puts(format_product(prod)) }
    end

    def handle_low_stock(_args, service)
      items = service.low_stock_products
      return @output.puts("No hay productos con stock bajo.") if items.empty?

      @output.puts("Alertas de stock bajo (#{items.size}):")
      items.each { |prod| @output.puts(format_product(prod)) }
    end

    def handle_report(_args, service)
      rep = service.valuation_report
      @output.puts("Reporte de valoración de inventario")
      @output.puts("SKUs totales: #{rep[:total_skus]} | Unidades: #{rep[:total_units]}")
      @output.puts("Valor total: $#{format_money(rep[:total_value_cents])} | Alertas: #{rep[:low_stock_count]}")
      rep[:by_category].each do |cat, stats|
        @output.puts("  - #{cat}: #{stats[:skus]} SKUs, #{stats[:units]} uds, $#{format_money(stats[:value_cents])}")
      end
    end

    def handle_delete(args, service)
      require_arg_count!(args, 1, "Uso: delete SKU")
      prod = service.delete_product(args[0])
      @output.puts("Producto eliminado: #{prod.sku} (#{prod.name})")
    end

    def require_arg_count!(args, min_count, usage_msg)
      raise ArgumentError, usage_msg if args.size < min_count
    end

    def format_product(prod)
      alert = prod.low_stock? ? " [LOW STOCK]" : ""
      "#{prod.sku} | #{prod.name} (#{prod.category}) | $#{format_money(prod.price_cents)} | " \
        "stock: #{prod.stock} (min: #{prod.min_stock})#{alert}"
    end

    def format_money(cents)
      format("%.2f", cents / 100.0)
    end

    def print_help(code)
      @output.puts("Comandos disponibles: add, stock-in, stock-out, search, low-stock, report, delete")
      code
    end
  end
end
