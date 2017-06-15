module WeChat::Bot
  class User
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

    def parse(obj)
      obj.each do |key, value|
        if attribute = mapping[key]
          sync(attribute, value)
        end
      end

      self
    end

    private

    def sync(attribute, value, data = false)
      if data
        @data[attribute.to_sym] = value
      else
        instance_variable_set("@#{attribute}", value)
      end
    end

    def attr(attribute)
      instance_variable_get("@#{attribute}")
    end

    def mapping
      {
        "NickName" => "nickname",
        "UserName" => "username",
      }
    end
  end
end
