# frozen_string_literal: true

require "securerandom"
require "time"

module RestApi
  # Entidad de dominio inmutable para un ticket de soporte técnico.
  class Ticket
    STATUSES = %w[open in_progress resolved closed].freeze
    PRIORITIES = %w[low medium high critical].freeze

    attr_reader :id, :title, :description, :status, :priority, :created_at, :updated_at

    def initialize(attrs)
      @id = (attrs[:id] || SecureRandom.uuid).to_s
      @title = validate_title!(attrs[:title])
      @description = validate_description!(attrs[:description])
      @status = validate_enum!(attrs[:status] || "open", STATUSES, "status")
      @priority = validate_enum!(attrs[:priority] || "medium", PRIORITIES, "priority")
      assign_timestamps(attrs)
      freeze
    end

    def with_updates(changes)
      merged = to_h.merge(symbolize_changes(changes))
      merged[:updated_at] = Time.now.utc.iso8601
      self.class.new(merged)
    end

    def to_h
      {
        id: id,
        title: title,
        description: description,
        status: status,
        priority: priority,
        created_at: created_at,
        updated_at: updated_at
      }
    end

    def self.from_hash(raw)
      symbolized = raw.to_h.transform_keys(&:to_sym)
      new(symbolized)
    end

    private

    def assign_timestamps(attrs)
      now = Time.now.utc.iso8601
      @created_at = (attrs[:created_at] || now).to_s
      @updated_at = (attrs[:updated_at] || now).to_s
    end

    def symbolize_changes(changes)
      changes.to_h.transform_keys(&:to_sym).slice(:title, :description, :status, :priority)
    end

    def validate_title!(val)
      clean = val.to_s.strip
      raise ValidationError, "El campo 'title' es obligatorio (mínimo 3 caracteres)" if clean.length < 3

      clean
    end

    def validate_description!(val)
      clean = val.to_s.strip
      raise ValidationError, "El campo 'description' es obligatorio" if clean.empty?

      clean
    end

    def validate_enum!(val, allowed, field_name)
      clean = val.to_s.strip.downcase
      return clean if allowed.include?(clean)

      raise ValidationError, "Valor inválido para '#{field_name}': #{val}. Permitidos: #{allowed.join(", ")}"
    end
  end
end
