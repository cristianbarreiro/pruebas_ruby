# frozen_string_literal: true

require "benchmark"

module Solutions
  module Advanced
    module LookupBenchmarkAnalyzer
      class BenchmarkAnalyzer
        MIN_DURATION_MS = 0.0001

        def self.compare(collection_size:, lookups_count:, seed: 42)
          new(collection_size: collection_size, lookups_count: lookups_count, seed: seed).compare
        end

        def initialize(collection_size:, lookups_count:, seed: 42)
          validate_positive_int!(collection_size, "collection_size")
          validate_positive_int!(lookups_count, "lookups_count")
          @collection_size = collection_size
          @lookups_count = lookups_count
          @seed = seed
        end

        def compare
          array_data, set_data, hash_data = build_structures
          targets = build_targets
          metrics = measure_all(array_data, set_data, hash_data, targets)
          verify_hits_consistency!(metrics)
          build_report(metrics)
        end

        private

        def validate_positive_int!(val, name)
          return if val.is_a?(Integer) && val.positive?

          raise ArgumentError, "#{name} debe ser un entero positivo mayor que 0"
        end

        def build_structures
          array_data = (1..@collection_size).to_a
          set_data = array_data.to_set
          hash_data = array_data.to_h { |item| [item, true] }
          [array_data, set_data, hash_data]
        end

        def build_targets
          rng = Random.new(@seed)
          tail_start = [(@collection_size * 0.75).to_i, 1].max
          Array.new(@lookups_count) do |idx|
            idx.even? ? rng.rand(tail_start..@collection_size) : @collection_size + idx + 1
          end
        end

        def measure_all(array_data, set_data, hash_data, targets)
          {
            array: measure_lookup(targets) { |key| array_data.include?(key) },
            set: measure_lookup(targets) { |key| set_data.include?(key) },
            hash: measure_lookup(targets) { |key| hash_data.key?(key) }
          }
        end

        def measure_lookup(targets, &lookup_block)
          hits = 0
          timing = Benchmark.measure do
            targets.each { |target| hits += 1 if lookup_block.call(target) }
          end
          {
            real_ms: (timing.real * 1000.0).round(4),
            cpu_ms: (timing.total * 1000.0).round(4),
            raw_real: [timing.real * 1000.0, MIN_DURATION_MS].max,
            hits: hits
          }
        end

        def verify_hits_consistency!(metrics)
          hit_counts = metrics.values.map { |entry| entry[:hits] }.uniq
          raise "Inconsistencia en conteo de aciertos entre estructuras" unless hit_counts.size == 1
        end

        def build_report(raw_metrics)
          ranked = raw_metrics.sort_by { |_key, data| data[:raw_real] }
          fastest_key, fastest_data = ranked.first
          slowest_key, slowest_data = ranked.last
          ratio = (slowest_data[:raw_real] / fastest_data[:raw_real]).round(2)
          {
            collection_size: @collection_size,
            lookups_count: @lookups_count,
            metrics: clean_metrics(raw_metrics),
            fastest: fastest_key,
            slowest: slowest_key,
            speedup_ratio: [ratio, 1.0].max
          }
        end

        def clean_metrics(raw_metrics)
          raw_metrics.transform_values do |entry|
            { real_ms: entry[:real_ms], cpu_ms: entry[:cpu_ms], hits: entry[:hits] }
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  report = Solutions::Advanced::LookupBenchmarkAnalyzer::BenchmarkAnalyzer.compare(
    collection_size: 5_000,
    lookups_count: 2_000
  )
  puts "Comparativa de búsqueda (Array vs Set vs Hash):"
  puts "  Más rápido: #{report[:fastest]} | Más lento: #{report[:slowest]} | Factor: #{report[:speedup_ratio]}x"
  report[:metrics].each { |kind, data| puts "  #{kind}: #{data[:real_ms]} ms (hits: #{data[:hits]})" }
end
