require "wechat/bot/http/adapter/js"
require "wechat/bot/http/adapter/xml"
require "wechat/bot/http/session"

require "wechat/bot/handler_list"
require "wechat/bot/handler"
require "wechat/bot/message"
require "wechat/bot/pattern"
require "wechat/bot/callback"

require "wechat/bot/configuration"
require "wechat/bot/cached_list"
require "wechat/bot/contact_list"
require "wechat/bot/contact"

require "logger"

module WeChat::Bot
  # 机器人的核心类
  class Core
    # 微信 API 客户端
    #
    # @return [Client]
    attr_reader :client

    # 当前登录用户信息
    #
    # @return [Contact]
    attr_reader :profile

    # 联系人列表
    #
    # @return [ContactList]
    attr_reader :contact_list

    # @return [Logger]
    attr_accessor :logger

    # @return [HandlerList]
    attr_reader :handlers

    # @return [Configuration]
    attr_reader :config

    # @return [Callback]
    # @api private
    attr_reader :callback

    def initialize(&block)
      defaults_logger

      @config = Configuration.new
      @handlers = HandlerList.new
      @callback = Callback.new(self)

      @client = Client.new(self)
      @profile = Contact.new(self)
      @contact_list = ContactList.new(self)

      instance_eval(&block) if block_given?
    end

    # 消息触发器
    #
    # @param [String, Symbol, Integer] event
    # @param [Regexp, Pattern, String] regexp
    # @param [Array<Object>] args
    # @yieldparam [Array<String>]
    # @return [Handler]
    def on(event, regexp = //, *args, &block)
      event = event.to_s.to_sym

      pattern = case regexp
                when Pattern
                  regexp
                when Regexp
                  Pattern.new(nil, regexp, nil)
                else
                  if event == :ctcp
                    Pattern.generate(:ctcp, regexp)
                  else
                    Pattern.new(/^/, /#{Regexp.escape(regexp.to_s)}/, /$/)
                  end
                end

      handler = Handler.new(self, event, pattern, {args: args, execute_in_callback: true}, &block)
      @handlers.register(handler)

      handler
    end

    # 用于设置 WeChat::Bot 的配置
    # 默认无需配置，需要定制化 yield {Core#config} 进行配置
    #
    # @yieldparam [Struct] config
    # @return [void] 没有返回值
    def configure
      yield @config
    end

    # 运行机器人
    #
    # @return [void]
    def start
      @client.login
      @client.contacts

      @contact_list.each do |c|
        @logger.debug "Contact: #{c}"
      end

      while true
        break unless @client.logged? || @client.alive?
        sleep 1
      end
    rescue Exception => e
      message = if e.is_a?(Interrupt)
        "你使用 Ctrl + C 终止了运行"
      else
        e.message
      end

      @logger.warn message

      @client.send_text(@config.fireman, "[告警] 意外下线\n#{message}\n#{e.backtrace.join("\n")}")
      @client.logout if @client.logged? && @client.alive?
    end

    private

    def defaults_logger
      @logger = Logger.new($stdout)
      # @logger.level = @config.verbose ? Logger::DEBUG : Logger::INFO
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "#{severity}\t[#{datetime.strftime("%Y-%m-%d %H:%M:%S.%2N")}]: #{msg}\n"
      end
    end
  end
end
