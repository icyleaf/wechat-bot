module WeChat::Bot
  class HandlerList
    include Enumerable

    def initialize
      @handlers = Hash.new {|h,k| h[k] = []}
      @mutex = Mutex.new
    end

    def register(handler)
      @mutex.synchronize do
        handler.bot.logger.debug "[on handler] Registering handler with pattern `#{handler.pattern}`, reacting on `#{handler.event}`"
        @handlers[handler.event].push(handler)
      end
    end

    def unregister(*handlers)
      @mutex.synchronize do
        handlers.each do |handler|
          @handlers[handler.event].delete(handler)
        end
      end
    end

    def dispatch(event, message = nil, *args)
      threads = []

      if handlers = find(event, message)
        already_run = Set.new
        handlers.each do |handler|
          next if already_run.include?(handler.block)
          already_run.add(handler.block)

          if message
            captures = message.match(handler.pattern.to_r(message), event).captures
          else
            captures = []
          end

          threads.push(handler.call(message, captures, args))
        end
      end

      threads
    end

    def find(type, message = nil)
      if handlers = @handlers[type]
        if message.nil?
          return handlers
        end

        handlers = handlers.select { |handler|
          message.match(handler.pattern.to_r(message), type)
        }.group_by {|handler| handler.group}

        handlers.values_at(*(handlers.keys - [nil])).map(&:first) + (handlers[nil] || [])
      end
    end

    def each(&block)
      @handlers.values.flatten.each(&block)
    end

    def stop_all
      each { |h| h.stop }
    end
  end
end
