# frozen_string_literal: true

module Solutions
  module Advanced
    module ThreadSafeWorkerPool
      class WorkerPool
        STOP_SIGNAL = :__worker_pool_stop__

        attr_reader :size

        def self.map(items, size: 4, &block)
          raise ArgumentError, "Se requiere un bloque de trabajo" unless block

          pool = new(size: size)
          items.each_with_index do |item, idx|
            pool.schedule(idx) { block.call(item) }
          end
          pool.shutdown
        end

        def initialize(size: 4)
          raise ArgumentError, "El tamaño del pool debe ser un entero >= 1" unless size.is_a?(Integer) && size >= 1

          @size = size
          @queue = Thread::Queue.new
          @mutex = Mutex.new
          @results = []
          @seq = 0
          @closed = false
          @workers = spawn_workers
        end

        def schedule(job_id = nil, &task)
          raise ArgumentError, "Debe proporcionar un bloque para la tarea" unless task

          @mutex.synchronize do
            raise "No se pueden encolar tareas en un pool cerrado" if @closed

            order = @seq
            @seq += 1
            actual_id = job_id.nil? ? order : job_id
            @queue.push([order, actual_id, task])
          end
          self
        end

        def shutdown
          should_stop = @mutex.synchronize do
            return ordered_results if @closed

            @closed = true
          end
          @size.times { @queue.push(STOP_SIGNAL) } if should_stop
          @workers.each(&:join)
          ordered_results
        end

        def stats
          @mutex.synchronize do
            succeeded = @results.count { |entry| entry[:result][:error].nil? }
            failed = @results.size - succeeded
            { total: @results.size, succeeded: succeeded, failed: failed }
          end
        end

        private

        def spawn_workers
          Array.new(@size) do
            Thread.new { worker_loop }
          end
        end

        def worker_loop
          loop do
            payload = @queue.pop
            break if payload.equal?(STOP_SIGNAL)

            order, job_id, task = payload
            outcome = execute_safely(job_id, task)
            @mutex.synchronize { @results << { order: order, result: outcome } }
          end
        end

        def execute_safely(job_id, task)
          { id: job_id, value: task.call, error: nil }
        rescue StandardError => e
          { id: job_id, value: nil, error: e }
        end

        def ordered_results
          @mutex.synchronize do
            @results.sort_by { |entry| entry[:order] }.map { |entry| entry[:result] }
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  inputs = [10, 20, 0, 40, 50]
  results = Solutions::Advanced::ThreadSafeWorkerPool::WorkerPool.map(inputs, size: 3) do |num|
    100 / num
  end

  puts "Resultados del WorkerPool concurrente:"
  results.each do |res|
    status = res[:error] ? "ERROR (#{res[:error].class})" : "OK (#{res[:value]})"
    puts "  Tarea #{res[:id]}: #{status}"
  end
end
