require "colorize"

module WeChat::Bot
  class Logger
    LEVELS = [:verbose, :debug, :info, :warn, :error, :fatal]

    # @return [Symbol]
    attr_accessor :level

    # @return [Mutex]
    attr_reader :mutex

    # @return [IO]
    attr_reader :output

    def initialize(output, bot)
      @output = output
      @bot = bot
      @mutex = Mutex.new
      @level = :info
    end

    def verbose(message)
      log(:verbose, message)
    end

    def debug(message)
      log(:debug, message)
    end

    def info(message)
      log(:info, message)
    end

    def warn(message)
      log(:warn, message)
    end

    def error(message)
      log(:error, message)
    end

    def fatal(exception)
      message = ["#{exception.backtrace.first}: #{exception.message} (#{exception.class})"]
      message.concat exception.backtrace[1..-1].map {|s| "\t" + s}
      log(:fatal, message.join("\n"))
    end

    def log(level, message)
      return unless can_log?(level)
      return if message.to_s.empty?

      @mutex.synchronize do
        message = format_message(format_general(message), level)
        @output.puts message
      end
    end

    private

    def can_log?(level)
      @level = :verbose if @bot.config.verbose
      LEVELS.index(level) >= LEVELS.index(@level)
    end

    def format_general(message)
      message
    end

    def format_message(message, level)
      send("format_#{level}", message)
    end

    def format_verbose(message)
      "VERBOSE [#{timestamp}] #{message.colorize(:light_black)}"
    end

    def format_debug(message)
      "DEBUG   [#{timestamp}] #{message.colorize(:light_black)}"
    end

    def format_info(message)
      "INFO    [#{timestamp}] #{message}"
    end

    def format_warn(message)
      "WRAN    [#{timestamp}] #{message.colorize(:yellow)}"
    end

    def format_error(message)
      "ERROR   [#{timestamp}] #{message.colorize(:light_red)}"
    end

    def format_fatal(message)
      "FATAL   [#{timestamp}] #{message.colorize(:red)}"
    end

    def timestamp
      Time.now.strftime("%Y-%m-%d %H:%M:%S.%2N")
    end
  end
end
