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

    # 群组成员列表
    #
    # 只有群组才有内容，根据 {#kind} 或 {#group?} 来判断
    # 不是群组类型的返回空数组
    #
    # @return [Hash]
    def members
      attr(:members)
    end

    # 联系人解析
    #
    # @param [Hash<Object, Object>] raw
    # @return [Contact]
    def parse(raw, update = false)
      @raw = raw

      parse_kind
      parse_members

      @raw.each do |key, value|
        if attribute = mapping[key]
          next if value.to_s.empty? && update

          sync(attribute, value)
        end
      end

      self
    end

    def update(raw)
      @raw = raw
      parse(@raw, true)
    end

    def to_s
      "#<#{self.class}:#{object_id.to_s(16)} username='#{username}' nickname='#{nickname}' kind='#{kind}'>"
    end

    private

    # 更新或新写入变量值
    #
    # @param [Symbol] attribute
    # @param [String, Integer, Hash] value
    # @param [Boolean] data
    # @return [void]
    def sync(attribute, value, data = false)
      value = value.convert_emoji if attribute.to_sym == :nickname

      # 满足群组类型且 nickname 为空时补充一个默认的群组名（参考微信 App 设计）
      if attribute.to_sym == :nickname && value.to_s.empty? && @kind == Kind::Group
        value = members.map {|m| m.nickname }.join("、")
      end

      if data
        @data[attribute.to_sym] = value
      else
        instance_variable_set("@#{attribute}", value)
      end
    end

    # 获取属性
    #
    # @param [Symbol] attribute
    # @param [Boolean] data 默认 false
    # @return [String, Integer, Hash]
    def attr(attribute, data = false)
      if data
        @data[attribute.to_sym]
      else
        instance_variable_get("@#{attribute}")
      end
    end

    # 解析联系人类型
    #
    # 详见 {Contact::Kind} 成员变量
    # @return [void]
    def parse_kind
      kind = if @bot.config.special_users.include?(@raw["UserName"])
               # 特殊账户
               Kind::Special
             elsif @raw["UserName"].include?("@@")
               # 群聊
               Kind::Group
             elsif @raw["VerifyFlag"] && (@raw["VerifyFlag"] & 8) != 0
               # 公众号
               Kind::MP
             else
               # 普通用户
               Kind::User
             end

      sync(:kind, kind)
    end

    # 解析群组成员列表
    #
    # 只有群组才有内容，根据 {#kind} 或 {#group?} 来判断
    #
    # @return [void]
    def parse_members
      members = []

      if @raw["MemberList"]
        @raw["MemberList"].each do |m|
          members.push(Contact.parse(m, @bot))
        end
      end

      sync(:members, members)
    end

    # 字段映射
    #
    # @return [Hash<String, String>]
    def mapping
      {
        "NickName" => "nickname",
        "UserName" => "username",
        "RemarkName" => "remarkname",
        "DisplayName" => "displayname",
        "Signature" => "signature",
        "Sex" => "sex",
        "Province" => "province",
        "City" => 'city'
      }
    end
  end
end
