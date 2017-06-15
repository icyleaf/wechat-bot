require "http/mime_type"
require "http/mime_type/adapter"
require "multi_xml"
# require "roxml"

module WeChat::Bot
  module HTTP
    module MimeType
      class XML < ::HTTP::MimeType::Adapter
        # Encodes object to js
        def encode(obj)
          "" # NO NEED encode
        end

        # Decodes js
        def decode(str)
          MultiXml.parse(str)
        end
      end
    end
  end

  ::HTTP::MimeType.register_adapter "text/xml", WeChat::Bot::HTTP::MimeType::XML
  ::HTTP::MimeType.register_alias   "text/xml", :xml
end
