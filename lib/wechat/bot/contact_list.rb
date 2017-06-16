module WeChat::Bot
  class ContactList < CachedList
    # 批量同步联系人数据
    #
    # 更多查看 {#sync} 接口
    # @param [Array<Hash>] 联系人数组
    # @return [ContactList]
    def batch_sync(list)
      list.each do |item|
        sync(item)
      end

      self
    end

    # 创建用户或更新用户数据
    #
    # @param [Hash] 微信接口返回的单个用户数据
    # @return [Contact]
    def sync(data)
      if data["NickName"] == @bot.profile.nickname
        contact = @bot.profile
      end

      @mutex.synchronize do
        if contact.nil?
          contact = Contact.parse(data, @bot)
          @cache[contact.username] ||= contact
        end

        contact
      end
    end

    def find(username)
      @mutex.synchronize do
        return @cache[username]
      end
    end
  end
end
