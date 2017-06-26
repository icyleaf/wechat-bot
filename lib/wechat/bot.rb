require "wechat/bot/ext/wechat_emoji_string"

require "wechat/bot/core"
require "wechat/bot/client"
require "wechat/bot/exception"
require "wechat/bot/version"

module WeChat::Bot
  def self.new(&block)
    WeChat::Bot::Core.new(&block)
  end
end
