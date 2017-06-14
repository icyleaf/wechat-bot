require "http/mime_type"
require "http/mime_type/adapter"

module RBChat
  module HTTP
    module MimeType
      class JS < ::HTTP::MimeType::Adapter
        # Encodes object to js
        def encode(obj)
          "" # NO NEED encode
        end

        # Decodes js
        def decode(str)
          str.split("window.").each_with_object({}) do |item, obj|
            key, value = item.split(/\s*=\s*/, 2)
            next unless key || value
            key = key.split(".")[-1]
            value = value.gsub(/^["']*(\S+?)["']*\s*;\s*$/, '\1')
            value = value.to_i if value =~ /^\d+$/

            obj[key] = value
          end
        end
      end
    end
  end

  ::HTTP::MimeType.register_adapter "text/javascript", RBChat::HTTP::MimeType::JS
  ::HTTP::MimeType.register_alias   "text/javascript", :js
end
