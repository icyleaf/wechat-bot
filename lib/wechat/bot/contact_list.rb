module WeChat::Bot
  # 微信联系人列表
  class ContactList < CachedList
    # 批量同步联系人数据
    #
    # 更多查看 {#sync} 接口
    # @param [Array<Hash>] list 联系人数组
    # @return [ContactList]
    def batch_sync(list)
      list.each do |item|
        sync(item)
      end

      self
    end

    def size
      @cache.size
    end

    # 创建用户或更新用户数据
    #
    # @param [Hash] data 微信接口返回的单个用户数据
    # @return [Contact]
    def sync(data)
      @mutex.synchronize do
        contact = Contact.parse(data, @bot)
        if @cache[contact.username]
          @cache[contact.username].update(data)
        else
          @cache[contact.username] = contact
        end

        contact
      end
    end

    # 查找用户
    #
    # @param [Hash] args 接受两个参数:
    #   - :nickname 昵称
    #   - :username 用户ID
    # @return [Contact]
    def find(**args)
      @mutex.synchronize do
        return @cache[args[:username]] if args[:username]

        if args[:nickname]
          @cache.each do |username, contact|
            return contact if contact.nickname == args[:nickname]
          end
        end
      end
    end
  end
end
