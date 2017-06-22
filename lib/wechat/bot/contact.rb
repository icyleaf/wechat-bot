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

    # 用户唯一 ID
    def username
      attr(:username)
    end

    # 用户昵称
    def nickname
      attr(:nickname)
    end

    # 备注名
    def remarkname
      attr(:remarkname)
    end

    # 群聊显示名
    def displayname
      attr(:displayname)
    end

    # 性别
    def sex
      attr(:sex)
    end

    # 个人签名
    def signature
      attr(:signature)
    end

    # 用户类型
    def kind
      attr(:kind)
    end

    # 省份
    def province
      attr(:province)
    end

    # 城市
    def city
      attr(:city)
    end

    # 是否特殊账户
    def special?
      kind == Kind::Special
    end

    # 是否群聊
    def group?
      kind == Kind::Group
    end

    # 是否公众号
    def mp?
      kind == Kind::MP
    end

    # 联系人解析
    #
    # @param [Hash<Object, Object>] raw
    # @return [Contact]
    def parse(raw)
      @raw = raw

      @raw.each do |key, value|
        if attribute = mapping[key]
          sync(attribute, value)
        end
      end

      parse_kind

      self
    end

    def to_s
      "#<#{self.class}:#{object_id.to_s(16)} @username='#{username}' @nickname='#{nickname}' @kind='#{kind}'>"
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

    def parse_kind
      kind = if @bot.config.special_users.include?(@raw["UserName"])
        # 特殊账户
        Kind::Special
      elsif @raw["UserName"].include?("@@")
        # 群聊
        Kind::Group
      elsif (@raw["VerifyFlag"] & 8) != 0
        # 公众号
        Kind::MP
      else
        # 普通用户
        Kind::User
      end

      sync(:kind, kind)
    end

    def mapping
      {
        "NickName" => "nickname",
        "UserName" => "username",
        "RemarkName" => "remarkname",
        "DisplayName" => "displayname"
        "Signature" => "signature",
        "Sex" => "sex",
        "Province" => "province",
        "City" => 'city'
      }
    end
  end
end
