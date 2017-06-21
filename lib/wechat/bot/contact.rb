module WeChat::Bot
  # 微信联系人
  #
  # 可以是用户、公众号、群组等
  class Contact
    # 联系人分类
    module Kind
      User = :user
      Group = :group
      MP = :mp
      Special = :special
    end

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
      kind == Kind::Special
    end

    def group?
      kind == Kind::Group
    end

    def mp?
      kind == Kind::MP
    end

    def parse(obj)
      obj.each do |key, value|
        if attribute = mapping[key]
          sync(attribute, value)
        end
      end

      kind = if @bot.config.special_users.include?(obj["UserName"])
        # 特殊账户
        Kind::Special
      elsif obj["UserName"].include?("@@")
        # 群聊
        Kind::Group
      elsif (obj["VerifyFlag"] & 8) != 0
        # 公众号
        Kind::MP
      else
        # 普通用户
        Kind::User
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
