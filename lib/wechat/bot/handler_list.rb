module WeChat::Bot
  # Handler 列表
  class HandlerList
    include Enumerable

    def initialize
      @handlers = Hash.new {|h,k| h[k] = []}
      @mutex = Mutex.new
    end

    # 注册 Handler
    #
    # @param [Handler]
    # @return [void]
    def register(handler)
      @mutex.synchronize do
        handler.bot.logger.debug "[on handler] Registering handler with pattern `#{handler.pattern}`, reacting on `#{handler.event}`"
        @handlers[handler.event].push(handler)
      end
    end

    # 取消注册 Handler
    #
    # @param [Array<Handler>]
    # @return [void]
    def unregister(*handlers)
      @mutex.synchronize do
        handlers.each do |handler|
          @handlers[handler.event].delete(handler)
        end
      end
    end

    # 分派执行 Handler
    #
    # @param [Symbol] event
    # @param [String] message
    # @param [Array] extra args
    # @return [Array<Thread>]
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

    # 查找匹配 Handler
    #
    # @param [Symbol] type
    # @param [String] message
    # @return [Hander]
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

    # 停止运行所有 Handler
    #
    # @return [void]
    def stop_all
      each { |h| h.stop }
    end
  end
end
