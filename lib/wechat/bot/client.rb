require "rqrcode"
require "logger"
require "uri"

module WeChat::Bot
  # 微信 API 类
  class Client
    def initialize(bot)
      @bot = bot
      clone!
    end

    # 微信登录
    def login
      return @bot.logger.info("你已经登录") if logged?

      check_count = 0
      until logged?
        check_count += 1
        @bot.logger.debug "尝试登录 (#{check_count})..."
        until uuid = qr_uuid
          @bot.logger.info "重新尝试获取登录二维码 ..."
          sleep 1
        end

        show_qr_code(uuid)

        until logged?
          status, status_data = login_status(uuid)
          case status
          when :logged
            @is_logged = true
            store_login_data(status_data["redirect_uri"])
            break
          when :scaned
            @bot.logger.info "请在手机微信确认登录 ..."
          when :timeout
            @bot.logger.info "扫描超时，重新获取登录二维码 ..."
            break
          end
        end

        break if logged?
      end

      @bot.logger.info "等待加载登录后所需资源 ..."
      login_loading
      update_notice_status

      @bot.logger.info "用户 [#{@bot.profile.nickname}] 登录成功！"

      start_runloop_thread
    rescue Exception => e
      message = if e.is_a?(Interrupt)
        "你使用 Ctrl + C 终止了运行"
      else
        e.message
      end

      @bot.logger.warn message

      send_text(@bot.config.fireman, "[告警] 意外下线\n#{message}")
      logout if logged? && alive?
    end

    # Runloop 监听
    def start_runloop_thread
      @is_alive = true
      retry_count = 0

      Thread.new do
        while alive?
          begin
            status = sync_check
            if status[:retcode] == "0"
              if status[:selector].nil?
                @is_alive = false
              elsif status[:selector] != "0"
                data = sync_messages
                if data["AddMsgCount"] > 0
                  data["AddMsgList"].each do |msg|
                    next if msg["FromUserName"] == @bot.profile.username

                    message = Message.new(msg, @bot)

                    events = [:message]
                    events.push(:text) if message.kind == Message::Kind::Text
                    events.push(:group) if msg["ToUserName"].include?("@@")

                    events.each do |event, *args|
                      @bot.handlers.dispatch(event, message, args)
                    end
                  end
                end
              end
            elsif status[:retcode] == "1100"
              @bot.logger.info("账户在手机上进行登出操作")
              @is_alive = false
              break
            elsif [ "1101", "1102" ].include?(status[:retcode])
              @bot.logger.info("账户在手机上进行登出或在其他地方进行登录操作操作")
              @is_alive = false
              break
            end

            retry_count = 0
          rescue Exception => ex
            retry_count += 1
            @bot.logger.error("#{ex.class.name}: #{ex.message}")
            @bot.logger.error("#{ex.backtrace.join("\n")}")
          end

          sleep 1
        end

        logout
      end
    end

    # 获取生成二维码的唯一识别 ID
    #
    # @return [String]
    def qr_uuid
      params = {
        "appid" => @bot.config.app_id,
        "fun" => "new",
        "lang" => "zh_CN",
        "_" => timestamp,
      }

      @bot.logger.info "获取登录唯一标识 ..."
      r = @session.get(File.join(@bot.config.auth_url, "jslogin") , params: params)
      data = r.parse(:js)

      return data["uuid"] if data["code"] == 200
    end

    # 获取二维码图片
    def show_qr_code(uuid, renderer = "ansi")
      @bot.logger.info "获取登录用扫描二维码 ... "
      url = File.join(@bot.config.auth_url, "l", uuid)
      qrcode = RQRCode::QRCode.new(url)

      # image = qrcode.as_png(
      #   resize_gte_to: false,
      #   resize_exactly_to: false,
      #   fill: "white",
      #   color: "black",
      #   size: 120,
      #   border_modules: 4,
      #   module_px_size: 6,
      # )
      # IO.write(QR_FILENAME, image.to_s)

      svg = qrcode.as_ansi(
        light: "\033[47m",
        dark: "\033[40m",
        fill_character: "  ",
        quiet_zone_size: 2
      )

      puts svg
    end

    # 处理微信登录
    #
    # @return [Array]
    def login_status(uuid)
      timestamp = timestamp
      params = {
        "loginicon" => "true",
        "uuid" => uuid,
        "tip" => 0,
        "r" => timestamp.to_i / 1579,
        "_" => timestamp,
      }

      r = @session.get(File.join(@bot.config.auth_url, "cgi-bin/mmwebwx-bin/login"), params: params)
      data = r.parse(:js)
      status = case data["code"]
      when 200 then :logged
      when 201 then :scaned
      when 408 then :waiting
      else          :timeout
      end

      [status, data]
    end

    # 保存登录返回的数据信息
    #
    # redirect_uri 有效时间是从扫码成功后算起大概是 300 秒，
    # 在此期间可以重新登录，但获取的联系人和群 ID 会改变
    def store_login_data(redirect_url)
      host = URI.parse(redirect_url).host
      r = @session.get(redirect_url)
      data = r.parse(:xml)

      store(
        skey: data["error"]["skey"],
        sid: data["error"]["wxsid"],
        uin: data["error"]["wxuin"],
        device_id: "e#{rand.to_s[2..17]}",
        pass_ticket: data["error"]["pass_ticket"],
      )

      @bot.config.servers.each do |server|
        if host == server[:index]
          update_servers(server)
          break
        end
      end

      raise RuntimeError, "没有匹配到对于的微信服务器: #{host}" unless store(:index_url)

      r
    end

    # 微信登录后初始化工作
    #
    # 掉线后 300 秒可以重新使用此 api 登录获取的联系人和群ID保持不变
    def login_loading
      url = "#{store(:index_url)}/webwxinit?r=#{timestamp}"
      r = @session.post(url, json: params_base_request)
      data = r.parse(:json)

      store(
        sync_key: data["SyncKey"],
        invite_start_count: data["InviteStartCount"].to_i,
      )

      @bot.profile.parse(data["User"])
      @bot.contact_list.batch_sync(data["ContactList"])

      r
    end

    # 更新通知状态（关闭手机提醒通知）
    #
    # 需要解密参数 Code 的值的作用，目前都用的是 3
    def update_notice_status
      url = "#{store(:index_url)}/webwxstatusnotify?lang=zh_CN&pass_ticket=#{store(:pass_ticket)}"
      params = params_base_request.merge({
        "Code"  => 3,
        "FromUserName" => @bot.profile.username,
        "ToUserName" => @bot.profile.username,
        "ClientMsgId" => timestamp
      })

      r = @session.post(url, json: params)
      r
    end

    # 检查微信状态
    #
    # 状态会包含是否有新消息、用户状态变化等
    #
    # @return [Hash] 状态数据数组
    #  - :retcode
    #    - 0 成功
    #    - 1100 用户登出
    #    - 1101 用户在其他地方登录
    #  - :selector
    #    - 0 无消息
    #    - 2 新消息
    #    - 6 未知消息类型
    #    - 7 需要调用 {#sync_messages}
    def sync_check
      url = "#{store(:push_url)}/synccheck"
      params = {
        "r" => timestamp,
        "skey" => store(:skey),
        "sid" => store(:sid),
        "uin" => store(:uin),
        "deviceid" => store(:device_id),
        "synckey" => params_sync_key,
        "_" => timestamp,
      }

      r = @session.get(url, params: params, timeout: [10, 60])
      data = r.parse(:js)["synccheck"]

      # raise RuntimeException "微信数据同步异常，原始返回内容：#{r.to_s}" if data.nil?

      @bot.logger.debug "HeartBeat: retcode/selector #{data[:retcode]}/#{data[:selector]}"
      data
    end

    # 获取微信消息数据
    #
    # 根据 {#sync_check} 接口返回有数据时需要调用该接口
    # @return [void]
    def sync_messages
      query = {
        "sid" => store(:sid),
        "skey" => store(:skey),
        "pass_ticket" => store(:pass_ticket)
      }
      url = "#{store(:index_url)}/webwxsync?#{URI.encode_www_form(query)}"
      params = params_base_request.merge({
        "SyncKey" => store(:sync_key),
        "rr" => "-#{timestamp}"
      })

      r = @session.post(url, json: params, timeout: [10, 60])
      data = r.parse(:json)

      @bot.logger.debug "Message: A/M/D/CM #{data["AddMsgCount"]}/#{data["ModContactCount"]}/#{data["DelContactCount"]}/#{data["ModChatRoomMemberCount"]}"

      File.open("webwxsync.txt", "a+") {|f| f.write(url); f.write(JSON.pretty_generate(data));f.write("\n\n")} if data["AddMsgCount"] > 0 || data["ModContactCount"] > 0 ||data["DelContactCount"] > 0 || data["ModChatRoomMemberCount"] > 0

      store(:sync_key, data["SyncCheckKey"])

      data
    end

    # 获取所有联系人列表
    #
    # 好友、群组、订阅号、公众号和特殊号
    #
    # @return [Hash] 联系人列表
    def contacts
      query = {
        "r" => timestamp,
        "pass_ticket" => store(:pass_ticket),
        "skey" => store(:skey)
      }
      url = "#{store(:index_url)}/webwxgetcontact?#{URI.encode_www_form(query)}"

      r = @session.post(url, json: {})
      data = r.parse(:json)

      @bot.contact_list.batch_sync(data["MemberList"])
    end

    # 消息发送
    #
    # @param [Symbol] type 消息类型，未知类型默认走 :text
    #   - :text 文本
    #   - :emoticon 表情
    #   - :image 图片
    # @param [String] username
    # @param [String] content
    # @return [Hash<Object,Object>] 发送结果状态
    def send(type, username, content)
      case type
      when :emoticon
        send_emoticon(username, content)
      else
        send_text(username, content)
      end
    end

    # 发送消息
    #
    # @param [String] username 目标UserName
    # @param [String] text 消息内容
    # @return [Hash<Object,Object>] 发送结果状态
    def send_text(username, text)
      url = "#{store(:index_url)}/webwxsendmsg"
      params = params_base_request.merge({
        "Scene" => 0,
        "Msg" => {
          "Type" => 1,
          "FromUserName" => @bot.profile.username,
          "ToUserName" => username,
          "Content" => text,
          "LocalID" => timestamp,
          "ClientMsgId" => timestamp,
        },
      })

      r = @session.post(url, json: params)
      r.parse(:json)
    end

    # 发送图片
    #
    # @param [String] username 目标 UserName
    # @param [String, File] 图片名或图片文件
    # @param [Hash] 非文本消息的参数（可选）
    # @return [Boolean] 发送结果状态
    # def send_image(username, image, media_id = nil)
    #   if media_id.nil?
    #     media_id = upload_file(image)
    #   end

    #   url = "#{store(:index_url)}/webwxsendmsgimg?fun=async&f=json"

    #   params = params_base_request.merge({
    #     "Scene" => 0,
    #     "Msg" => {
    #       "Type" => type,
    #       "FromUserName" => @bot.profile.username,
    #       "ToUserName" => username,
    #       "MediaId" => mediaId,
    #       "LocalID" => timestamp,
    #       "ClientMsgId" => timestamp,
    #     },
    #   })

    #   r = @session.post(url, json: params)
    #   r.parse(:json)
    # end

    # 发送表情
    #
    # 支持微信表情和自定义表情
    #
    # @param [String] username
    # @param [String] emoticon_id
    #
    # @return [Hash<Object,Object>] 发送结果状态
    def send_emoticon(username, emoticon_id)
      query = {
        'fun' => 'sys',
        'pass_ticket' => store(:pass_ticket),
        'lang' => 'zh_CN'
      }
      url = "#{store(:index_url)}/webwxsendemoticon?#{URI.encode_www_form(query)}"
      params = params_base_request.merge({
        "Scene" => 0,
        "Msg" => {
          "Type" => 47,
          'EmojiFlag' => 2,
          "FromUserName" => @bot.profile.username,
          "ToUserName" => username,
          "LocalID" => timestamp,
          "ClientMsgId" => timestamp,
        },
      })

      emoticon_key = emoticon_id.include?("@") ? "MediaId" : "EMoticonMd5"
      params["Msg"][emoticon_key] = emoticon_id

      r = @session.post(url, json: params)
      r.parse(:json)
    end

    # 下载图片
    #
    # @param [String] message_id
    # @return [TempFile]
    def download_image(message_id)
      url = "#{store(:index_url)}/webwxgetmsgimg"
      params = {
        "msgid" => message_id,
        "skey" => store(:skey)
      }

      r = @session.get(url, params: params)
      body = r.body

      # FIXME: 不知道什么原因，下载的是空字节
      # 返回的 headers 是 {"Connection"=>"close", "Content-Length"=>"0"}
      temp_file = Tempfile.new(["emoticon", ".gif"])
      while data = r.readpartial
        temp_file.write data
      end
      temp_file.close

      temp_file
    end

    # 登出
    #
    # @return [void]
    def logout
      url = "#{store(:index_url)}/webwxlogout"
      params = {
        "redirect" => 1,
        "type"  => 1,
        "skey"  => store(:skey)
      }

      r = @session.get(url, params: params)

      @bot.logger.info "用户 [#{@bot.profile.nickname}] 登出成功！"
      clone!
    end

    # 获取登录状态
    #
    # @return [Boolean]
    def logged?
      @is_logged
    end

    # 获取是否在线（存活）
    #
    # @return [Boolean]
    def alive?
      @is_alive
    end

    private

    # 保存和获取存储数据
    #
    # @return [Object] 获取数据返回该变量对应的值类型
    # @return [void] 保存数据时无返回值
    def store(*args)
      return @store[args[0].to_sym] = args[1] if args.size == 2

      if args.size == 1
        obj = args[0]
        return @store[obj.to_sym] if obj.is_a?(String) || obj.is_a?(Symbol)

        obj.each do |key, value|
          @store[key.to_sym] = value
        end if obj.is_a?(Hash)
      end
    end

    # 生成 13 位 unix 时间戳
    # @return [String]
    def timestamp
      Time.now.strftime("%s%3N")
    end

    # 匹配对于的微信服务器
    #
    # @param [Hash<String, String>] servers
    # @return [void]
    def update_servers(servers)
      server_scheme = "https"
      server_path = "/cgi-bin/mmwebwx-bin"
      servers.each do |name, host|
        store("#{name}_url", "#{server_scheme}://#{host}#{server_path}")
      end
    end

    # 微信接口请求参数 BaseRequest
    #
    # @return [Hash<String, String>]
    def params_base_request
      return @base_request if @base_request

      @base_request = {
        "BaseRequest" => {
          "Skey" => store(:skey),
          "Sid" => store(:sid),
          "Uin" => store(:uin),
          "DeviceID" => store(:pass_ticket),
        }
      }
    end

    # 微信接口参数序列后的 SyncKey
    #
    # @return [void]
    def params_sync_key
      store(:sync_key)["List"].map {|i| i.values.join("_") }.join("|")
    end

    # 初始化变量
    #
    # @return [void]
    def clone!
      @session = HTTP::Session.new(@bot)
      @is_logged = @is_alive = false
      @store = {}
    end
  end
end
