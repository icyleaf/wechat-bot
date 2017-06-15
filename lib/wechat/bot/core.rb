require "wechat/bot/configuration"
require "logger"

module WeChat::Bot
  class Core
    # The logger s
    #
    # @return [Logger]
    attr_accessor :logger

    # @return [Config]
    attr_reader :config

    attr_reader :client

    # @return [Array<User>]
    attr_reader :friend_list

    # @return [Array<User>]
    attr_reader :group_list

    # @return [Array<User>]
    attr_reader :mp_list

    def initialize(&block)
      @logger = Logger.new(STDOUT)
      @config = Configuration.new

      @client = Client.new(self)

      @friend_list = @group_list = @mp_list = []

      instance_eval(&block) if block_given?
    end

    # This method is used to set a bot"s options. It indeed does
    # nothing else but yielding {Bot#config}, but it makes for a nice DSL.
    #
    # @yieldparam [Struct] config the bot"s config
    # @return [void]
    def configure
      yield @config
    end

    def start
      @client.login
      @client.run
    end
  end
end
