# frozen_string_literal: true

module Solutions
  module Advanced
    module NotificationServiceDi
      class DeliveryError < StandardError; end
      class RateLimitExceededError < StandardError; end

      class FakeClock
        def initialize(initial_time = 1_700_000_000.0)
          @current = initial_time.to_f
        end

        def now
          @current
        end

        def advance(seconds)
          @current += seconds.to_f
        end
      end

      class MemoryLogger
        attr_reader :entries

        def initialize
          @entries = []
        end

        def info(message)
          @entries << { level: :info, message: message }
        end

        def warn(message)
          @entries << { level: :warn, message: message }
        end

        def error(message)
          @entries << { level: :error, message: message }
        end
      end

      class MemoryChannel
        attr_reader :name, :deliveries

        def initialize(name)
          @name = name.to_sym
          @deliveries = []
        end

        def deliver(recipient:, message:)
          payload = { recipient: recipient, message: message }
          @deliveries << payload
          payload
        end
      end

      class FailingChannel
        def initialize(reason = "Fallo en proveedor externo")
          @reason = reason
        end

        def deliver(recipient:, message:)
          raise StandardError, "#{@reason} (#{recipient}: #{message[0, 10]})"
        end
      end

      class NotificationDispatcher
        def initialize(channels:, clock: FakeClock.new, logger: MemoryLogger.new, rate_limit: 3, window_seconds: 60)
          @channels = channels.transform_keys(&:to_sym)
          @clock = clock
          @logger = logger
          @rate_limit = rate_limit
          @window_seconds = window_seconds
          @history = Hash.new { |hash, key| hash[key] = [] }
        end

        def dispatch(recipient:, message:, channel:, fallback: nil)
          validate_inputs!(recipient, message, channel)
          now = current_timestamp
          enforce_rate_limit!(recipient, now)
          used_channel, fallback_used = attempt_with_fallback(recipient, message, channel.to_sym, fallback&.to_sym)
          record_success(recipient, used_channel, fallback_used, now)
        end
        alias notify dispatch

        private

        def validate_inputs!(recipient, message, channel)
          raise ArgumentError, "Destinatario requerido" if recipient.to_s.strip.empty?
          raise ArgumentError, "Mensaje requerido" if message.to_s.strip.empty?
          raise ArgumentError, "Canal desconocido: #{channel}" unless @channels.key?(channel.to_sym)
        end

        def current_timestamp
          @clock.respond_to?(:now) ? @clock.now.to_f : @clock.call.to_f
        end

        def enforce_rate_limit!(recipient, now)
          timestamps = @history[recipient]
          timestamps.reject! { |stamp| (now - stamp) >= @window_seconds }
          return if timestamps.size < @rate_limit

          @logger.warn("Rate limit excedido para #{recipient}")
          raise RateLimitExceededError, "Límite de #{@rate_limit} envíos excedido para #{recipient}"
        end

        def attempt_with_fallback(recipient, message, primary, fallback)
          return [primary, false] if try_channel(primary, recipient, message)
          return [fallback, true] if fallback && @channels.key?(fallback) && try_channel(fallback, recipient, message)

          @logger.error("Fallo definitivo enviando a #{recipient}")
          raise DeliveryError, "No fue posible entregar la notificación a #{recipient}"
        end

        def try_channel(channel_key, recipient, message)
          result = @channels.fetch(channel_key).deliver(recipient: recipient, message: message)
          return true if result

          @logger.warn("Canal #{channel_key} devolvió false para #{recipient}")
          false
        rescue StandardError => e
          @logger.warn("Fallo en canal #{channel_key}: #{e.message}")
          false
        end

        def record_success(recipient, used_channel, fallback_used, now)
          @history[recipient] << now
          @logger.info("Notificación enviada a #{recipient} vía #{used_channel}")
          {
            status: :delivered,
            recipient: recipient,
            channel: used_channel,
            fallback_used: fallback_used,
            timestamp: now
          }
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  mod = Solutions::Advanced::NotificationServiceDi
  clock = mod::FakeClock.new
  logger = mod::MemoryLogger.new
  dispatcher = mod::NotificationDispatcher.new(
    channels: { email: mod::FailingChannel.new("SMTP caído"), sms: mod::MemoryChannel.new(:sms) },
    clock: clock,
    logger: logger,
    rate_limit: 2
  )

  res = dispatcher.dispatch(recipient: "ana@example.com", message: "Tu código es 9876", channel: :email, fallback: :sms)
  puts "Resultado del envío con fallback: #{res.inspect}"
  puts "Registros del logger: #{logger.entries.size}"
end
