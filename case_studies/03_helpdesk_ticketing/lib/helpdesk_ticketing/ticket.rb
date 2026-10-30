# frozen_string_literal: true

require "time"
require_relative "errors"
require_relative "transition_policy"

module HelpdeskTicketing
  # Entidad de dominio que representa un ticket de mesa de ayuda y su ciclo de vida.
  class Ticket
    VALID_PRIORITIES = %i[low medium high critical].freeze

    attr_reader :id, :title, :description, :requester, :priority, :category,
                :status, :assignee, :created_at, :resolved_at, :history

    def initialize(id:, title:, description:, requester:, **opts)
      @id = validate_presence(id, "ID").upcase
      @title = validate_presence(title, "título")
      @description = validate_presence(description, "descripción")
      @requester = validate_presence(requester, "solicitante")
      assign_metadata(opts)
      assign_timestamps_and_history(opts)
    end

    def assign_to(technician)
      @assignee = validate_presence(technician, "técnico asignado")
      self
    end

    def transition_to(new_status, policy: TransitionPolicy, timestamp: nil, note: nil)
      target = new_status.to_s.strip.downcase.to_sym
      policy.validate!(@status, target)
      moment = normalize_time(timestamp)
      record_history_entry(@status, target, moment, note)
      @status = target
      @resolved_at = (target == :resolved ? moment : nil)
      self
    end

    def resolved?
      @status == :resolved
    end

    def resolution_seconds
      return nil if @resolved_at.nil?

      (Time.iso8601(@resolved_at) - Time.iso8601(@created_at)).round(2)
    end

    def to_h
      {
        id: @id, title: @title, description: @description, requester: @requester,
        priority: @priority.to_s, category: @category, status: @status.to_s,
        assignee: @assignee, created_at: @created_at, resolved_at: @resolved_at,
        history: @history.map { |entry| serialize_history_entry(entry) }
      }
    end

    def self.from_h(raw)
      data = raw.transform_keys(&:to_sym)
      new(
        id: data[:id], title: data[:title], description: data[:description],
        requester: data[:requester], priority: data.fetch(:priority, :medium),
        category: data.fetch(:category, "general"), status: data.fetch(:status, :open),
        assignee: data[:assignee], created_at: data[:created_at],
        resolved_at: data[:resolved_at], history: data.fetch(:history, [])
      )
    end

    private

    def assign_metadata(opts)
      @priority = validate_priority(opts.fetch(:priority, :medium))
      @category = validate_presence(opts.fetch(:category, "general"), "categoría").downcase
      @status = validate_status(opts.fetch(:status, :open))
      raw_assignee = opts[:assignee]
      @assignee = raw_assignee.nil? || raw_assignee.to_s.strip.empty? ? nil : raw_assignee.to_s.strip
    end

    def assign_timestamps_and_history(opts)
      @created_at = normalize_time(opts[:created_at])
      raw_resolved = opts[:resolved_at]
      @resolved_at = raw_resolved.nil? || raw_resolved.to_s.strip.empty? ? nil : normalize_time(raw_resolved)
      @history = opts.fetch(:history, []).map { |item| normalize_history_entry(item) }
    end

    def record_history_entry(from_st, to_st, moment, note)
      @history << {
        from: from_st,
        to: to_st,
        at: moment,
        note: note.to_s.strip
      }
    end

    def normalize_history_entry(item)
      row = item.transform_keys(&:to_sym)
      {
        from: row[:from].to_sym,
        to: row[:to].to_sym,
        at: row[:at].to_s,
        note: row[:note].to_s
      }
    end

    def serialize_history_entry(entry)
      {
        from: entry[:from].to_s,
        to: entry[:to].to_s,
        at: entry[:at],
        note: entry[:note]
      }
    end

    def validate_presence(val, field_name)
      text = val.to_s.strip
      raise Errors::ValidationError, "El campo #{field_name} es obligatorio" if text.empty?

      text
    end

    def validate_priority(val)
      sym = val.to_s.strip.downcase.to_sym
      return sym if VALID_PRIORITIES.include?(sym)

      raise Errors::ValidationError, "Prioridad inválida: #{val}"
    end

    def validate_status(val)
      sym = val.to_s.strip.downcase.to_sym
      return sym if TransitionPolicy.valid_status?(sym)

      raise Errors::ValidationError, "Estado inválido: #{val}"
    end

    def normalize_time(val)
      return Time.now.utc.iso8601 if val.nil? || val.to_s.strip.empty?
      return val.utc.iso8601 if val.is_a?(Time)

      Time.iso8601(val.to_s).utc.iso8601
    rescue ArgumentError
      raise Errors::ValidationError, "Formato de fecha inválido: #{val}"
    end
  end
end
