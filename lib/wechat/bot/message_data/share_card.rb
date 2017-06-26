module WeChat::Bot::MessageData
  class ShareCard
    def self.parse(raw)
      self.new(raw)
    end

    # @return [String]
    attr_reader :title

    # @return [String]
    attr_reader :link

    # @return [String]
    attr_reader :description

    # @return [String, Nil]
    attr_reader :thumb_image

    # @return [String]
    attr_reader :from_user

    # @return [String, Nil]
    attr_reader :app

    # @return [Hash<Symbol, String>, Hash<Symbol, Nil>]
    attr_reader :mp

    def initialize(raw)
      @raw = MultiXml.parse(raw.gsub("<br/>", ""))
      parse
    end

    def parse
      @title = @raw["msg"]["appmsg"]["title"]
      @link = @raw["msg"]["appmsg"]["url"]
      @description = @raw["msg"]["appmsg"]["des"]
      @thumb_image = @raw["msg"]["appmsg"]["thumb_url"]
      @from_user = @raw["msg"]["fromusername"]
      @app = @raw["msg"]["appname"]
      @mp = {
        username: @raw["msg"]["sourceusername"],
        nickname: @raw["msg"]["sourcedisplayname"],
      }
    end
  end
end
