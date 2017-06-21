module WeChat::Bot
  # 微信联系人
  #
  # 可以是用户、公众号、群组等
  class Contact
    def self.parse(obj, bot)
      self.new(bot).parse(obj)
    end

    def initialize(bot)
      @bot = bot
      @data = {}
    end

    def nickname
      attr(:nickname)
    end

    def username
      attr(:username)
    end

    def kind
      attr(:kind)
    end

    def special?
      kind == :special
    end

    def group?
      kind == :group
    end

    def mp?
      kind == :mp
    end

    def parse(obj)
      obj.each do |key, value|
        if attribute = mapping[key]
          sync(attribute, value)
        end
      end

      kind = if @bot.config.special_users.include?(obj["UserName"])
        # 特殊账户
        :special
      elsif obj["UserName"].include?("@@")
        # 群聊
        :group
      elsif (obj["VerifyFlag"] & 8) != 0
        # 公众号
        :mp
      else
        # 普通用户
        :user
      end

      sync(:kind, kind)

      self
    end

    private

    def sync(attribute, value, data = false)
      value = value.convert_emoji if attribute.to_sym == :nickname

      if data
        @data[attribute.to_sym] = value
      else
        instance_variable_set("@#{attribute}", value)
      end
    end

    def attr(attribute, data = false)
      if data
        @data[attribute.to_sym]
      else
        instance_variable_get("@#{attribute}")
      end
    end

    def mapping
      {
        "NickName" => "nickname",
        "UserName" => "username",
      }
    end
  end
end
