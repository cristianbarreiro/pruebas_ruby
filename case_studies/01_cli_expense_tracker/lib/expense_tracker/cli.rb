# frozen_string_literal: true

require "optparse"

module ExpenseTracker
  # Interfaz de línea de comandos para el gestor de gastos personales.
  # Recibe los flujos de salida por inyección para facilitar pruebas sin consola.
  class CLI
    DEFAULT_STORAGE = File.expand_path("../../storage/expenses.json", __dir__)

    USAGE = <<~TEXT
      Uso: expense-tracker <comando> [opciones]

      Comandos:
        add          Registra un ingreso o gasto (--type, --amount, --category, --desc, [--date])
        list         Lista operaciones con filtros opcionales (--type, --category, --from, --to, --query)
        summary      Muestra el balance total y el desglose por categoría
        export-csv   Exporta las operaciones filtradas a un archivo CSV (--out)
        delete       Elimina una operación por su ID (--id)
        help         Muestra esta ayuda
    TEXT

    def initialize(out: $stdout, err: $stderr, default_storage: DEFAULT_STORAGE)
      @out = out
      @err = err
      @default_storage = default_storage
    end

    def call(argv)
      args = argv.dup
      command = args.shift
      options = parse_options(args)
      ledger = Ledger.new(JsonStore.new(options.fetch(:storage, @default_storage)))

      dispatch(command, ledger, options)
    rescue ArgumentError, OptionParser::ParseError, DataCorruptError, NotFoundError => e
      @err.puts("Error: #{e.message}")
      1
    end

    private

    def dispatch(command, ledger, options)
      case command
      when "add" then handle_add(ledger, options)
      when "list" then handle_list(ledger, options)
      when "summary" then handle_summary(ledger, options)
      when "export-csv" then handle_export(ledger, options)
      when "delete" then handle_delete(ledger, options)
      when nil, "help", "--help", "-h" then print_ok(USAGE)
      else fail_unknown(command)
      end
    end

    def handle_add(ledger, options)
      txn = ledger.record(
        type: options[:type],
        amount: options[:amount],
        category: options[:category],
        description: options[:desc],
        date: options.fetch(:date, Date.today.iso8601)
      )
      print_ok("Registrado: #{txn.to_display}")
    end

    def handle_list(ledger, options)
      transactions = filtered_transactions(ledger, options)
      return print_ok("No se encontraron operaciones.") if transactions.empty?

      transactions.each { |txn| @out.puts(txn.to_display) }
      0
    end

    def handle_summary(ledger, options)
      summary = ledger.summarize(filtered_transactions(ledger, options))
      @out.puts(format("Operaciones: %d", summary.count))
      @out.puts(format("Ingresos:    +$%.2f", summary.income))
      @out.puts(format("Gastos:      -$%.2f", summary.expense))
      @out.puts(format("Balance:      $%.2f", summary.balance))
      print_categories(summary.by_category)
      0
    end

    def print_categories(by_category)
      return if by_category.empty?

      @out.puts("Por categoría:")
      by_category.sort_by { |cat, _| cat }.each do |cat, cents|
        @out.puts(format("  %-14<cat>s $%<amount>.2f", cat: cat, amount: cents / 100.0))
      end
    end

    def handle_export(ledger, options)
      out_path = options[:out]
      raise ArgumentError, "Indica la ruta de destino con --out RUTA" if out_path.nil? || out_path.strip.empty?

      transactions = filtered_transactions(ledger, options)
      CsvExporter.export(transactions, out_path)
      print_ok("Exportadas #{transactions.size} operaciones a #{out_path}")
    end

    def handle_delete(ledger, options)
      target_id = options[:id]
      raise ArgumentError, "Indica el identificador con --id ID" if target_id.nil? || target_id.strip.empty?

      ledger.delete(target_id)
      print_ok("Operación #{target_id} eliminada.")
    end

    def filtered_transactions(ledger, options)
      ledger.list(
        type: options[:type],
        category: options[:category],
        from_date: options[:from],
        to_date: options[:to],
        query: options[:query]
      )
    end

    def parse_options(args)
      options = {}
      parser = OptionParser.new do |opts|
        configure_core_flags(opts, options)
        configure_filter_flags(opts, options)
      end
      parser.parse!(args)
      options
    end

    def configure_core_flags(opts, options)
      opts.on("--type TYPE") { |val| options[:type] = val }
      opts.on("--amount AMOUNT") { |val| options[:amount] = val }
      opts.on("--category CATEGORY") { |val| options[:category] = val }
      opts.on("--desc DESCRIPTION") { |val| options[:desc] = val }
      opts.on("--date YYYY-MM-DD") { |val| options[:date] = val }
      opts.on("--id ID") { |val| options[:id] = val }
    end

    def configure_filter_flags(opts, options)
      opts.on("--from YYYY-MM-DD") { |val| options[:from] = val }
      opts.on("--to YYYY-MM-DD") { |val| options[:to] = val }
      opts.on("--query TEXT") { |val| options[:query] = val }
      opts.on("--out PATH") { |val| options[:out] = val }
      opts.on("--storage PATH") { |val| options[:storage] = val }
    end

    def print_ok(text)
      @out.puts(text)
      0
    end

    def fail_unknown(command)
      @err.puts("Comando desconocido: #{command}\n\n#{USAGE}")
      1
    end
  end
end
