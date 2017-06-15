require "wechat/bot/http/adapter/js"
require "wechat/bot/http/adapter/xml"
require "wechat/bot/http/session"

require "wechat/bot/configuration"
require "wechat/bot/cached_list"
require "wechat/bot/user_list"
require "wechat/bot/user"

require "logger"

module WeChat::Bot
  class Core
    # The logger s
    #
    # @return [Logger]
    attr_accessor :logger

    # @return [UserList<User>]
    attr_reader :friend_list

    # @return [UserList<User>]
    attr_reader :group_list

    # @return [UserList<User>]
    attr_reader :mp_list

    attr_reader :profile

    # @return [Config]
    attr_reader :config

    # @return [HTTP::Client]
    attr_reader :client

    def initialize(&block)
      defaults_logger

      @config = Configuration.new
      @client = Client.new(self)
      @profile = User.new(self)
      @friend_list = @group_list = @mp_list = UserList.new(self)

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

    private

    def defaults_logger
      @logger = Logger.new($stdout)
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "#{severity}\t[#{datetime.strftime("%Y-%m-%d %H:%M:%S.%2N")}]: #{msg}\n"
      end
    end
  end
end
