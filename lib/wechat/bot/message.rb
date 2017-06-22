module WeChat::Bot
  # 微信消息
  class Message
    # 消息类型
    module Kind
      Text = :text
      Image = :image
      Voice = :voice
      ShortVideo = :short_video
      Emoticon = :emoticon
      ShareLink = :share_link
      # RedPacage = :red_package
      # BusinessCard = :business_card
      # MusicLink = :music_link
      System = :system
      Unkown = :unkown
    end

    GROUP_MESSAGE_REGEX = /^(@\w+):<br\/>(.*)$/
    AT_MESSAGE_REGEX = /@([^\s]+) (.*)/

    # @return [String]
    attr_reader :raw

    # @return [Array<Symbol>]
    attr_reader :events

    # @return [Core]
    attr_reader :bot

    # @return [Time]
    attr_reader :time

    # @return [Message::Kind]
    attr_reader :kind

    # @return [Contact::Kind]
    attr_reader :source

    # @return [Contact]
    attr_reader :from

    # @return [Contact]
    attr_reader :group

    # @return [String]
    attr_reader :message

    def initialize(raw, bot)
      @raw = raw
      @bot = bot

      @events  = []
      @time    = Time.now
      @statusmsg_mode = nil

      @bot.logger.debug "Message Raw: #{@raw}"

      parse
    end

    #
    def reply(text, **user)
      to_user = user[:username]
      user[:nickname]

      @bot.client.send_text(to_user, text)
    end

    # 解析微信消息
    #
    # @return [void]
    def parse
      parse_source
      parse_kind

      message = @raw["Content"].convert_emoji
      message = CGI.unescape_html(message) if @kinde != Message::Kind::Text
      if match = group_message(message)
        from_username = match[0]
        message = match[1]
      end

      @message = message
      @from = @bot.contact_list.find(username: @raw["FromUserName"])

      parse_events
    end

    # 消息匹配
    #
    # @param [String, Regex, Pattern] regexp 匹配规则
    # @param [String, Symbol] type 消息类型
    # @return [MatchData] 匹配结果
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

    # 解析消息来源
    #
    # 特殊账户/群聊/公众号/用户
    #
    # @return [void]
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

    # 解析消息类型
    #
    #  - 1: Text 文本消息
    #  - 3: Image 图片消息
    #  - 34: Voice 语言消息
    #  - 42: BusinessCard 名片消息
    #  - 47: Emoticon 微信表情
    #  - 49: ShareLink 分享链接消息
    #  - 62: ShortVideo 短视频消息
    #  - 1000: System 系统消息
    #  - Unkown 未知消息
    #
    # @return [void]
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
                Message::Kind::Emoticon
              when 49
                Message::Kind::ShareLink
              when 10000
                Message::Kind::System
              else
                Message::Kind::Unkown
              end
    end

    # 解析 Handler 的事件
    #
    #  - `:message` 用户消息
    #    - `:text` 文本消息
    #  - `:group` 群聊消息
    #    - `:at_message` @ 消息
    #
    # @return [void]
    def parse_events
      @events << :message
      @events << @kind
      @events << @source

      if @source == :group && @raw["Content"] =~ /@([^\s]+)\s+(.*)/
        @events << :at_message
      end
    end

    # 解析用户的群消息
    #
    # 群消息格式：
    #     @FromUserName:<br>Message
    #
    # @param [String] message 原始消息
    # @return [Array<Object>] 返回两个值的数组
    #   - 0 from_username
    #   - 1 message
    def group_message(message)
      if match = GROUP_MESSAGE_REGEX.match(message)
        return [match[1], at_message(match[2])]
      end

      false
    end

    # 尝试解析群聊中的 @ 消息
    #
    # 群消息格式：
    #     @ToNickNameUserName Message
    #
    # @param [String] message 原始消息
    # @return [String] 文本消息，如果不是 @ 消息返回原始消息
    def at_message(message)
      if match = AT_MESSAGE_REGEX.match(message)
        return match[2].strip
      end

      message
    end
  end
end
