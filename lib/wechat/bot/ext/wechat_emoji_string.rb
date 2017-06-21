module WeChat::Bot
  module WeChatEmojiString
    def convert_emoji
      emoji_regex = /<span class="emoji emoji(\w+)"><\/span>/
      if match = self.match(emoji_regex)
        return self.gsub(emoji_regex, [match[1].hex].pack("U"))
      end

      self
    end
  end
end

class String
  include WeChat::Bot::WeChatEmojiString
end
