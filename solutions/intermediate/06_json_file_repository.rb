# frozen_string_literal: true

# = Repositorio de archivos JSON con escritura atómica

require "fileutils"
require "json"
require "tempfile"
require "tmpdir"

module Solutions
  module Intermediate
    module JsonFileRepository
      class CorruptedStorageError < StandardError; end

      class Repository
        attr_reader :file_path

        def initialize(file_path)
          @file_path = File.expand_path(file_path)
          FileUtils.mkdir_p(File.dirname(@file_path))
        end

        def save(record)
          normalized = normalize_record(record)
          store = read_store
          store[normalized[:id].to_s] = normalized
          atomic_write(store)
          normalized
        end

        def find(record_id)
          read_store[record_id.to_s]
        end

        def all
          read_store.values
        end

        def delete(record_id)
          store = read_store
          removed = store.delete(record_id.to_s)
          atomic_write(store) if removed
          removed
        end

        private

        def normalize_record(record)
          raise ArgumentError, "Record must be a Hash" unless record.is_a?(Hash)

          symbolized = record.transform_keys(&:to_sym)
          rec_id = symbolized[:id].to_s.strip
          raise ArgumentError, "Record must contain a non-empty :id" if rec_id.empty?

          symbolized.merge(id: rec_id).freeze
        end

        def read_store
          return {} unless File.exist?(@file_path)

          parsed = JSON.parse(File.read(@file_path))
          raise CorruptedStorageError, "Root JSON element must be an Object" unless parsed.is_a?(Hash)

          parsed.transform_values { |val| symbolize_record(val) }
        rescue JSON::ParserError => e
          raise CorruptedStorageError, "Invalid JSON in storage: #{e.message}"
        end

        def symbolize_record(raw)
          raise CorruptedStorageError, "Entry must be a JSON Object" unless raw.is_a?(Hash)

          raw.transform_keys(&:to_sym).freeze
        end

        def atomic_write(store)
          dir = File.dirname(@file_path)
          Tempfile.create(["repo", ".json"], dir) do |temp|
            temp.write(JSON.pretty_generate(store))
            temp.flush
            temp.close
            FileUtils.mv(temp.path, @file_path)
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  Dir.mktmpdir do |dir|
    repo = Solutions::Intermediate::JsonFileRepository::Repository.new(File.join(dir, "items.json"))
    repo.save(id: "u1", name: "Ada Lovelace", role: "engineer")
    puts "Found: #{repo.find("u1").inspect}"
  end
end
