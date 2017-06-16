require "wechat/bot/http/adapter/js"
require "wechat/bot/http/adapter/xml"
require "wechat/bot/http/session"

require "wechat/bot/configuration"
require "wechat/bot/cached_list"
require "wechat/bot/user_list"
require "wechat/bot/user"

require "logger"

module WeChat::Bot
  # 机器人的核心类
  class Core
    # @return [Logger]
    attr_accessor :logger

    # 好友列表
    #
    # @return [UserList<User>]
    attr_reader :friend_list

    # 群组列表
    #
    # @return [UserList<User>]
    attr_reader :group_list

    # 订阅号和公众号列表
    #
    # @return [UserList<User>]
    attr_reader :mp_list

    # 当前登录用户信息
    #
    # @return [User]
    attr_reader :profile

    # @return [Configuration]
    attr_reader :config

    # 微信 API 客户端
    #
    # @return [Client]
    attr_reader :client

    def initialize(&block)
      defaults_logger

      @config = Configuration.new
      @client = Client.new(self)
      @profile = User.new(self)
      @friend_list = @group_list = @mp_list = UserList.new(self)

      instance_eval(&block) if block_given?
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
    def start
      @client.login
      while true
        break unless @client.logged? || @client.alive?
        sleep 1
      end
    rescue Interrupt
      @logger.info "你使用 Ctrl + C 终止了运行"
    ensure
      @client.logout if @client.logged? || @client.alive?
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
