# frozen_string_literal: true

module Solutions
  module Advanced
    module MiddlewarePipeline
      Context = Data.define(:request, :metadata, :response, :halted, :error, :trace) do
        def self.build(request = {})
          new(
            request: request.dup.freeze,
            metadata: {}.freeze,
            response: nil,
            halted: false,
            error: nil,
            trace: [].freeze
          )
        end

        def halted?
          halted
        end

        def with_meta(**pairs)
          with(metadata: metadata.merge(pairs).freeze)
        end

        def with_response(resp)
          with(response: resp.dup.freeze)
        end

        def add_trace(step_name)
          with(trace: (trace + [step_name.to_s]).freeze)
        end

        def halt!(message, status: 400)
          with(
            halted: true,
            error: message,
            response: { status: status, error: message }.freeze
          )
        end
      end

      class AuthMiddleware
        def initialize(valid_tokens = { "secret-token" => "usr-1" })
          @valid_tokens = valid_tokens.dup.freeze
        end

        def call(ctx)
          traced = ctx.add_trace("auth")
          token = traced.request[:token]
          user_id = @valid_tokens[token]
          return traced.halt!("Unauthorized: invalid or missing token", status: 401) unless user_id

          traced.with_meta(user_id: user_id)
        end
      end

      class ValidationMiddleware
        def initialize(required_keys = %i[action])
          @required_keys = required_keys.map(&:to_sym).freeze
        end

        def call(ctx)
          traced = ctx.add_trace("validation")
          payload = traced.request[:payload]
          return traced.halt!("Unprocessable Entity: payload must be a Hash", status: 422) unless payload.is_a?(Hash)

          missing = @required_keys.select { |key| payload[key].nil? || payload[key].to_s.strip.empty? }
          return traced.halt!("Unprocessable Entity: missing #{missing.join(", ")}", status: 422) if missing.any?

          traced
        end
      end

      class EnrichmentMiddleware
        def initialize(request_id: "req-default", service_version: "1.0")
          @request_id = request_id
          @service_version = service_version
        end

        def call(ctx)
          ctx.add_trace("enrichment").with_meta(
            request_id: @request_id,
            service_version: @service_version
          )
        end
      end

      class HandlerMiddleware
        def call(ctx)
          ctx.add_trace("handler").with_response(
            status: 200,
            data: ctx.request[:payload],
            user_id: ctx.metadata[:user_id],
            request_id: ctx.metadata[:request_id]
          )
        end
      end

      class Pipeline
        def initialize(steps = [])
          @steps = steps.dup
        end

        def use(middleware = nil, &block)
          step = middleware || block
          raise ArgumentError, "Debe proporcionar un middleware o bloque con #call" unless step.respond_to?(:call)

          @steps << step
          self
        end

        def call(input)
          initial_ctx = input.is_a?(Context) ? input : Context.build(input)
          @steps.reduce(initial_ctx) do |ctx, step|
            break ctx if ctx.halted?

            step.call(ctx)
          end
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  mod = Solutions::Advanced::MiddlewarePipeline
  pipeline = mod::Pipeline.new
                          .use(mod::AuthMiddleware.new("token-abc" => "user-42"))
                          .use(mod::ValidationMiddleware.new(%i[item quantity]))
                          .use(mod::EnrichmentMiddleware.new(request_id: "req-101"))
                          .use(mod::HandlerMiddleware.new)

  ok_result = pipeline.call(token: "token-abc", payload: { item: "Monitor", quantity: 1 })
  puts "Ejecución completa: status=#{ok_result.response[:status]} trace=#{ok_result.trace.inspect}"

  halted_result = pipeline.call(token: "wrong", payload: { item: "Monitor", quantity: 1 })
  puts "Cortocircuito en auth: status=#{halted_result.response[:status]} trace=#{halted_result.trace.inspect}"
end
