module WeChat::Bot
  class Callback
    # @return [Bot]
    attr_reader :bot

    def initialize(bot)
      @bot = bot
    end

    # (see Bot#synchronize)
    def synchronize(name, &block)
      @bot.synchronize(name, &block)
    end
  end
end
