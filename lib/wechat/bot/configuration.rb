require 'ostruct'

module WeChat::Bot
  class Configuration < OpenStruct
    # 默认配置
    #
    # @return [Hash]
    def self.default_config
      {
        # Bot Configurations
        verbose: false,
        fireman: 'filehelper',

        # WeChat Configurations
        app_id: 'wx782c26e4c19acffb',
        auth_url: 'https://login.weixin.qq.com',
        servers: [
          {
            index: 'wx.qq.com',
            file: 'file.wx.qq.com',
            push: 'webpush.wx.qq.com',
          },
          {
            index: 'wx2.qq.com',
            file: 'file.wx2.qq.com',
            push: 'webpush.wx2.qq.com',
          },
          {
            index: 'wx8.qq.com',
            file: 'file.wx8.qq.com',
            push: 'webpush.wx8.qq.com',
          },
          {
            index: 'wechat.com',
            file: 'file.web.wechat.com',
            push: 'webpush.web.wechat.com',
          },
          {
            index: 'web2.wechat.com',
            file: 'file.web2.wechat.com',
            push: 'webpush.web2.wechat.com',
          },
        ],
        cookies: 'wechat-bot-cookies.txt',
        special_users: [
          'newsapp', 'filehelper', 'weibo', 'qqmail',
          'fmessage', 'tmessage', 'qmessage', 'qqsync',
          'floatbottle', 'lbsapp', 'shakeapp', 'medianote',
          'qqfriend', 'readerapp', 'blogapp', 'facebookapp',
          'masssendapp', 'meishiapp', 'feedsapp', 'voip',
          'blogappweixin', 'brandsessionholder', 'weixin',
          'weixinreminder', 'officialaccounts', 'wxitil',
          'notification_messages', 'wxid_novlwrv3lqwv11',
          'gh_22b87fa7cb3c', 'userexperience_alarm',
        ],
        user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.86 Safari/537.36',
      }
    end

    def initialize(defaults = nil)
      defaults ||= self.class.default_config
      super(defaults)
    end

    # @return [Hash]
    def to_h
      @table.clone
    end
  end
end
