require "wechat/bot/version"
require "wechat/bot/core"
require "wechat/bot/client"
require "wechat/bot/exception"
require "wechat/bot/ext/wechat_emoji_string"

module WeChat
  module Bot
    def self.new(&block)
      WeChat::Bot::Core.new(&block)
    end
  end
end
