module WeChat::Bot
  class Message
    # 消息类型
    module Kind
      Text = :text
      Image = :image
      Voice = :voice
      ShortVideo = :short_video
      GifEmoji = :gif_emoji
      # RedPacage = :red_package
      # BusinessCard = :business_card
      # Link = :link
      # MusicLink = :music_link
      System = :system
      Unkown = :unkown
    end

    attr_reader :raw

    attr_reader :events

    attr_reader :bot

    attr_reader :time

    attr_reader :kind

    attr_reader :user

    attr_reader :message

    def initialize(raw, bot)
      @raw = raw
      @bot = bot
      @matches = {:ctcp => {}, :action => {}, :other => {}}
      @events  = []
      @time    = Time.now
      @statusmsg_mode = nil

      parse
    end

    def reply(text)
      @bot.client.send_text(@user.username, text)
    end

    def parse
      @user = @bot.contact_list.find(@raw["FromUserName"])
      # @to_user = @bot.contact_list.find(@raw["ToUserName"])
      @kind = parse_kind(@raw["MsgType"])
      if @kind == Kind::Text
        @message = @raw["Content"]
      end
    end

    def match(regexp, type)
      # text = ""
      # case type
      # when :ctcp
      #   text = ctcp_message
      # when :action
      #   text = action_message
      # else
      #   text = message.to_s
      #   type = :other
      # end

      # if strip_colors
      #   text = Cinch::Formatting.unformat(text)
      # end

      @message.match(regexp)
    end

    def parse_kind(type)
      case type
      when 1
        Kind::Text
      when 3
        Kind::Image
      when 34
        Kind::Voice
      when 42
        Kind::BusinessCard
      when 62
        Kind::ShortVideo
      when 47
        Kind::GifEmoji
      when 10000
        Kind::System
      else
        Kind::Unkown
      end
    end
  end
end
