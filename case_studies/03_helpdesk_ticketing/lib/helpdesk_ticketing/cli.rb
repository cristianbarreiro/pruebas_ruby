# frozen_string_literal: true

require_relative "errors"
require_relative "json_repository"
require_relative "ticket_service"

module HelpdeskTicketing
  # Interfaz de línea de comandos con flujos de salida y error inyectables.
  class CLI
    DEFAULT_DB = File.expand_path("../../data/sample_tickets.json", __dir__)

    COMMAND_HANDLERS = {
      "create" => :handle_create,
      "assign" => :handle_assign,
      "transition" => :handle_transition,
      "list" => :handle_list,
      "stats" => :handle_stats
    }.freeze

    attr_reader :out, :err

    def initialize(out: $stdout, err: $stderr, service: nil, db_path: DEFAULT_DB)
      @out = out
      @err = err
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
      @err.puts("Error: #{e.message}")
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
      TicketService.new(repository: repo)
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

    def handle_create(args, service)
      require_arg_count!(args, 3, "Uso: create TITULO DESCRIPCION SOLICITANTE [PRIORIDAD] [CATEGORIA]")
      ticket = service.create_ticket(
        title: args[0], description: args[1], requester: args[2],
        priority: args[3] || :medium, category: args[4] || "general"
      )
      @out.puts("Ticket creado: #{format_ticket(ticket)}")
    end

    def handle_assign(args, service)
      require_arg_count!(args, 2, "Uso: assign TICKET_ID TECNICO")
      ticket = service.assign_ticket(args[0], args[1..].join(" "))
      @out.puts("Ticket #{ticket.id} asignado a #{ticket.assignee}")
    end

    def handle_transition(args, service)
      require_arg_count!(args, 2, "Uso: transition TICKET_ID NUEVO_ESTADO [NOTA]")
      note_text = args[2..]&.join(" ")
      ticket = service.transition_status(args[0], args[1], note: note_text)
      @out.puts("Ticket #{ticket.id} actualizado a estado #{ticket.status}")
    end

    def handle_list(args, service)
      filters = parse_list_filters(args)
      items = service.search(**filters)
      return @out.puts("No se encontraron tickets.") if items.empty?

      items.each { |ticket| @out.puts(format_ticket(ticket)) }
    end

    def handle_stats(_args, service)
      rep = service.stats
      @out.puts("Estadísticas de Mesa de Ayuda (Total: #{rep[:total]})")
      @out.puts("Por estado: #{format_tally(rep[:by_status])}")
      @out.puts("Por prioridad: #{format_tally(rep[:by_priority])}")
      @out.puts("Por técnico: #{format_tally(rep[:by_technician])}")
      @out.puts("Tiempo medio de resolución: #{rep[:average_resolution_seconds]}s")
    end

    def parse_list_filters(args)
      filters = { status: nil, priority: nil, assignee: nil, query: nil }
      words = []
      args.each do |arg|
        apply_filter_arg(arg, filters, words)
      end
      filters[:query] = words.join(" ") unless words.empty?
      filters
    end

    def apply_filter_arg(arg, filters, words)
      if arg.start_with?("--status=")
        filters[:status] = arg.split("=", 2).last
      elsif arg.start_with?("--priority=")
        filters[:priority] = arg.split("=", 2).last
      elsif arg.start_with?("--assignee=")
        filters[:assignee] = arg.split("=", 2).last
      else
        words << arg
      end
    end

    def require_arg_count!(args, min_count, usage_msg)
      raise ArgumentError, usage_msg if args.size < min_count
    end

    def format_ticket(ticket)
      tech = ticket.assignee || "sin-asignar"
      "#{ticket.id} | [#{ticket.status.upcase}] (#{ticket.priority}) #{ticket.title} " \
        "| req: #{ticket.requester} | tech: #{tech}"
    end

    def format_tally(hash)
      return "ninguno" if hash.empty?

      hash.map { |key, val| "#{key}=#{val}" }.join(", ")
    end

    def print_help(code)
      @out.puts("Comandos disponibles: create, assign, transition, list, stats")
      code
    end
  end
end
