
module WeChat::Bot
  class Handler
    # @return [Core]
    attr_reader :bot

    # @return [Symbol]
    attr_reader :event

    # @return [String]
    attr_reader :pattern

    # @return [Array]
    attr_reader :args

    # @return [Proc]
    attr_reader :block

    # @return [Symbol]
    attr_reader :group

    # @return [ThreadGroup]
    # @api private
    attr_reader :thread_group

    def initialize(bot, event, pattern, options = {}, &block)
      options              = {
        :group => nil,
        :execute_in_callback => false,
        :strip_colors => false,
        :args => []
      }.merge(options)

      @bot = bot
      @event = event
      @pattern = pattern
      @block = block
      @group = options[:group]
      @execute_in_callback = options[:execute_in_callback]
      @args = options[:args]

      @thread_group = ThreadGroup.new
    end

    def call(message, captures, arguments)
      bargs = captures + arguments

      thread = Thread.new {
        @bot.logger.debug "[New thread] For #{self}: #{Thread.current} -- #{@thread_group.list.size} in total."
        begin
          if @execute_in_callback
            @bot.callback.instance_exec(message, *@args, *bargs, &@block)
          else
            @block.call(message, *@args, *bargs)
          end
        rescue => e
          @bot.logger.error e
        ensure
          @bot.logger.debug "[Thread done] For #{self}: #{Thread.current} -- #{@thread_group.list.size - 1} remaining."
        end
      }

      @thread_group.add(thread)
      thread
    end

    def stop
      @bot.logger.debug "[Stopping handler] Stopping all threads of handler #{self}: #{@thread_group.list.size} threads..."
      @thread_group.list.each do |thread|
        Thread.new do
          @bot.logger.debug "[Ending thread] Waiting 10 seconds for #{thread} to finish..."
          thread.join(10)
          @bot.logger.debug "[Killing thread] Killing #{thread}"
          thread.kill
        end
      end
    end

    # @return [String]
    def to_s
      # TODO maybe add the number of running threads to the output?
      "#<Cinch::Handler @event=#{@event.inspect} pattern=#{@pattern.inspect}>"
    end
  end
end
