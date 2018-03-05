require "http/mime_type"
require "http/mime_type/adapter"
require "multi_xml"
# require "roxml"

module WeChat::Bot
  module HTTP
    module MimeType
      # XML 代码解析
      # 提示：不可逆转
      class XML < ::HTTP::MimeType::Adapter
        # Encodes object to js
        def encode(_)
          "" # NO NEED encode
        end

        # 转换 XML 代码为 Hash
        #
        # @return [Hash]
        def decode(str)
          MultiXml.parse(str)
        end
      end
    end
  end

  ::HTTP::MimeType.register_adapter "text/xml", WeChat::Bot::HTTP::MimeType::XML
  ::HTTP::MimeType.register_alias   "text/xml", :xml
end
