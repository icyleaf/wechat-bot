module WeChat::Bot
  # 微信消息
  class Message
    # 消息类型
    module Kind
      Text = :text
      Image = :image
      Voice = :voice
      ShortVideo = :short_video
      GifEmoji = :gif_emoji
      ShareLink = :share_link
      # RedPacage = :red_package
      # BusinessCard = :business_card
      # MusicLink = :music_link
      System = :system
      Unkown = :unkown
    end

    GROUP_MESSAGE_REGEX = /^(@\w+):<br\/>(.*)$/
    AT_MESSAGE_REGEX = /@([^\s]+) (.*)/

    attr_reader :raw

    attr_reader :events

    attr_reader :bot

    attr_reader :time

    attr_reader :kind

    attr_reader :group

    attr_reader :user

    attr_reader :message

    def initialize(raw, bot)
      @raw = raw
      @bot = bot
      @matches = {:ctcp => {}, :action => {}, :other => {}}
      @events  = []
      @time    = Time.now
      @statusmsg_mode = nil

      @bot.logger.debug "Message Raw: #{@raw}"

      parse
    end

    def reply(text)
      @bot.client.send_text(@user.username, text)
    end

    def parse
      parse_source
      parse_kind

      @user = @bot.contact_list.find(@raw["FromUserName"])
      # @to_user = @bot.contact_list.find(@raw["ToUserName"])

      message = @raw["Content"].convert_emoji
      message = CGI.unescape_html(message) if @kinde != Message::Kind::Text
      if match = group_message(message)
        from_username = match[0]
        message = match[1]
      end

      @message = message

      parse_events
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

    def parse_source
      @source = if @bot.config.special_users.include?(@raw["FromUserName"])
                  # 特殊账户
                  Contact::Kind::Special
                elsif @raw["FromUserName"].include?("@@")
                  # 群聊
                  Contact::Kind::Group
                elsif (@raw["RecommendInfo"]["VerifyFlag"] & 8) != 0
                  # 公众号
                  Contact::Kind::MP
                else
                  # 普通用户
                  Contact::Kind::User
                end
    end

    def parse_kind
      @kind = case @raw["MsgType"]
              when 1
                Message::Kind::Text
              when 3
                Message::Kind::Image
              when 34
                Message::Kind::Voice
              when 42
                Message::Kind::BusinessCard
              when 62
                Message::Kind::ShortVideo
              when 47
                Message::Kind::GifEmoji
              when 49
                Message::Kind::ShareLink
              when 10000
                Message::Kind::System
              else
                Message::Kind::Unkown
              end
    end

    def parse_events
      @events << :message
      @events << @kind
      @events << @group

      if @source == :group && @raw["Content"] =~ /@([^\s]+)\s+(.*)/
        @events << :at_message
      end
    end

    def group_message(message)
      if match = GROUP_MESSAGE_REGEX.match(message)
        return [match[1], at_message(match[2])]
      end

      false
    end

    def at_message(message)
      if match = AT_MESSAGE_REGEX.match(message)
        return match[2].strip
      end

      message
    end
  end
end
