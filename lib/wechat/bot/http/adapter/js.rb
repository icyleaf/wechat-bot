require "http/mime_type"
require "http/mime_type/adapter"

module WeChat::Bot
  module HTTP
    module MimeType
      # Javascript 代码解析
      # 用于解析微信 API 返回的部分 JS 代码，
      # 提示：不可逆转
      class JS < ::HTTP::MimeType::Adapter
        # Encodes object to js
        def encode(obj)
          "" # NO NEED encode
        end

        # 转换 JS 代码为 Hash
        #
        # @return [Hash]
        def decode(str)
          str.split("window.").each_with_object({}) do |item, obj|
            key, value = item.split(/\s*=\s*/, 2)
            next unless key || value
            key = key.split(".")[-1]
            obj[key] = eval(value)
          end
        end
      end
    end
  end

  ::HTTP::MimeType.register_adapter "text/javascript", WeChat::Bot::HTTP::MimeType::JS
  ::HTTP::MimeType.register_alias   "text/javascript", :js
end
