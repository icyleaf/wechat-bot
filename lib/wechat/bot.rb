require "wechat/bot/http/adapter/js"
require "wechat/bot/http/adapter/xml"
require "wechat/bot/http/session"
require "wechat/bot/core"
require "wechat/bot/client"
require "wechat/bot/version"

module WeChat::Bot
  def self.new(&block)
    WeChat::Bot::Core.new(&block)
  end
end
