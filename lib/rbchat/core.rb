require "rqrcode"
require "logger"
require "uri"

module RBChat
  class Core
    QR_FILENAME = "wx_qr.png".freeze
    APP_ID = "wx782c26e4c19acffb"

    def initialize(logger = nil)
      default_logger(logger)
      @session = HTTP::Session.new

      @is_logged = false
      @is_alive = false
      @store = {}
    end

    def run
      return @logger.info "尚未登录" unless logged? || alive?
      while true
        sleep 1
      end
    rescue Exception => e
      @logger.info "你使用 Ctrl + C 终止了运行"
    ensure
      logout if logged? && alive?
    end

    def login
      return @logger.info("你已经登录") if logged?

      check_count = 0
      until logged?
        check_count += 1
        @logger.debug "尝试登录 (#{check_count})..."
        until uuid = qr_uuid
          @logger.info "重新尝试获取登录二维码 ..."
          sleep 1
        end

        qr_code(uuid)

        until logged?
          status, status_data = login_status(uuid)
          case status
          when :logged
            @is_logged = true
            store_login_data(status_data["redirect_uri"])
            break
          when :scaned
            @logger.info "请在手机微信确认登录 ..."
          when :timeout
            @logger.info "扫描超时，重新获取登录二维码 ..."
            break
          end
        end

        break if logged?
      end

      @logger.info "等待加载登录后所需资源 ..."
      wx_init_web
      wx_status_notify

      @logger.info "用户 [#{@store[:user][:nickname]}] 登录成功！"

      runloop
    rescue Exception => e
      @logger.info "你使用 Ctrl + C 终止了运行"
    ensure
      logout if logged? && alive?
    end

    def qr_uuid
      params = {
        "appid" => APP_ID,
        "fun" => "new",
        "lang" => "zh_CN",
        "_" => unix_timestamp,
      }

      @logger.info "获取登录唯一标识 ..."
      r = @session.get("jslogin", params: params)
      data = r.parse(:js)

      return data["uuid"] if data["code"] == 200
    end

    def qr_code(uuid, renderer = "ansi")
      @logger.info "获取登录用扫描二维码 ... "
      url = File.join(HTTP::Session::AUTH_URL, "l", uuid)
      @logger.debug "URL: #{url}"
      qrcode = RQRCode::QRCode.new(url)

      # image = qrcode.as_png(
      #   resize_gte_to: false,
      #   resize_exactly_to: false,
      #   fill: 'white',
      #   color: 'black',
      #   size: 120,
      #   border_modules: 4,
      #   module_px_size: 6,
      # )
      # IO.write(QR_FILENAME, image.to_s)

      svg = qrcode.as_ansi(
        light: "\033[47m",
        dark: "\033[40m",
        fill_character: '  ',
        quiet_zone_size: 2
      )

      puts svg
    end

    def login_status(uuid)
      timestamp = unix_timestamp
      params = {
        "loginicon" => "true",
        "uuid" => uuid,
        "tip" => 0,
        "r" => timestamp.to_i / 1579,
        "_" => timestamp,
      }

      r = @session.get("cgi-bin/mmwebwx-bin/login", params: params)
      data = r.parse(:js)
      status = case data["code"]
      when 200 then :logged
      when 201 then :scaned
      when 408 then :waiting
      else          :timeout
      end

      [status, data]
    end

    def store_login_data(url)
      r = @session.get(url)
      data = r.parse(:xml)

      @store[:info] = {
        skey: data["error"]["skey"],
        sid: data["error"]["wxsid"],
        uin: data["error"]["wxuin"],
        device_id: "e#{rand.to_s[2..17]}",
        pass_ticket: data["error"]["pass_ticket"],
      }

      @store[:base_request] = {
        "BaseRequest" => {
          "Skey" => data["error"]["skey"],
          "Sid" => data["error"]["wxsid"],
          "Uin" => data["error"]["wxuin"],
          "DeviceID" => data["error"]["pass_ticket"],
        }
      }

      host = URI.parse(url).host
      wx_servers[:servers].each do |server|
        if host == server[:index]
          @store[:servers] = current_server(server)
        end
      end
      @store[:servers] = {
        index: "#{wx_servers[:scheme]}://#{host}#{wx_servers[:path]}",
        file: "#{wx_servers[:scheme]}://#{host}#{wx_servers[:path]}",
        push: "#{wx_servers[:scheme]}://#{host}#{wx_servers[:path]}",
      } unless @current_server

      @store[:device_id] = "e#{rand.to_s[2..17]}"
      r
    end

    def wx_init_web
      url = "#{@store[:servers][:index]}/webwxinit?r=#{unix_timestamp(10)}"

      r = @session.post(url, json: @store[:base_request])
      data = r.parse(:json)

      @store[:user] = {
        username: data["User"]["UserName"],
        nickname: data["User"]["NickName"],
      }

      @store[:sync_key] = data["SyncKey"]
      # @store[:sync_key] = data["SyncKey"]["List"].map {|k| k.values[-1]}.join("|")
      @store[:invite_start_count] = data["InviteStartCount"].to_i

      @store[:contacts] = data["ContactList"]
      r
    end

    def wx_status_notify
      url = "#{@store[:servers][:index]}/webwxstatusnotify?lang=zh_CN&pass_ticket=#{@store[:info][:pass_ticket]}"
      params = @store[:base_request].merge({
        "Code"  => 3,
        "FromUserName" => @store[:user][:username],
        "ToUserName" => @store[:user][:username],
        "ClientMsgId" => unix_timestamp(10)
      })

      r = @session.post(url, json: params)
      # data = r.parse(:json)
      @logger.debug r.to_s
      r
    end

    def runloop
      @is_alive = true
      retry_count = 0

      Thread.new do
        while alive?
          begin
            status = wx_heartbeat
            if status[:retcode] == "1100"
              @logger.info("账户在手机上进行登出操作")
              @is_alive = false
            elsif status[:retcode] == "1101"
              @logger.info("账户已在其他地方进行登录操作")
              @is_alive = false
            elsif status[:retcode] == "1102"
              @logger.info("账户在手机上进行登出操作")
              @is_alive = false
            elsif status[:retcode] == "0"
              if status[:selector].nil?
                @is_alive = false
              elsif status[:selector] != "0"
                sync_messages
              end
            end

            retry_count = 0
          rescue Exception => ex
            retry_count += 1
            @logger.error("#{ex.class.name}: #{ex.message}")
            @logger.error("#{ex.backtrace.join("\n")}")
          end

          sleep 1
        end

        logout
      end
    end

    def wx_heartbeat
      url = "#{@store[:servers][:push]}/synccheck"
      timestamp = unix_timestamp
      params = @store[:info].merge({
        "r" => timestamp,
        "_" => timestamp,
      })

      r = @session.get(url, params: params) # .timeout(write: 10, connect: 10, read: 40)
      data = r.parse(:js)

      raise RuntimeException "微信数据同步异常，原始返回内容：#{r.to_s}" if data.nil?

      data["synccheck"]
    end

    def sync_messages
      query = {
        "sid" => @store[:info][:sid],
        "skey" => @store[:info][:skey],
        "pass_ticket" => @store[:info][:pass_ticket]
      }
      url = "#{@store[:servers][:index]}/webwxsync?#{URI.encode_www_form(query)}"
      params = @store[:base_request].merge({
        "SyncKey" => @store[:sync_key],
        "rr" => unix_timestamp(10)
      })

      r = @session.post(url, json: params) # timeout(write: 10, connect: 10, read: 40).
      data = r.parse(:json)
      @logger.debug "sync_messages Content: #{data}"
    end

    # 获取当前会话列表
    def contacts
      query = {
        "r" => unix_timestamp(10),
        "pass_ticket" => @store[:info][:pass_ticket],
        "skey" => @store[:info][:skey]
      }
      url = "#{@store[:servers][:index]}/webwxgetcontact?#{URI.encode_www_form(query)}"

      r = @session.post(url, json: {})
      data = r.parse(:json)
      @logger.debug "contacts Content: #{data}"
    end

    def logout
      url = "#{@store[:servers][:index]}/webwxlogout"
      params = {
        "redirect" => 1,
        "type"  => 1,
        "skey"  => @store[:info][[:skey]]
      }

      r = @session.get(url, params: params)

      @logger.info "用户 [#{@store[:user][:nickname]}] 登出成功！"
      cleanup!
    end

    def logged?
      @is_logged
    end

    def alive?
      @is_alive
    end

    private

    def default_logger(logger)
      @logger = logger || Logger.new($stdout)
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "#{severity}\t[#{datetime.strftime('%Y-%m-%d %H:%M:%S.%2N')}]: #{msg}\n"
      end
    end

    def unix_timestamp(digit = 13)
      case digit
      when 13
        Time.now.strftime('%s%3N')
      else
        Time.now.to_i.to_s
      end
    end

    def current_server(servers)
      servers.each_with_object do |(name, host), obj|
        obj[name] = "#{wx_servers[:scheme]}://#{host}#{wx_servers[:path]}"
      end
    end

    def cleanup!
      @session = HTTP::Session.new

      @store = {}
      @is_alive = false
      @is_logged = false
    end

    def wx_servers
      return @servers if @servers

      @servers = {
        scheme: "https",
        path: "/cgi-bin/mmwebwx-bin",
        servers: [
          {
            index: "qq.com",
            file: "file.wx.qq.com",
            push: "webpush.wx.qq.com",
          },
          {
            index: "wx2.qq.com",
            file: "file.wx2.qq.com",
            push: "webpush.wx.qq.com",
          },
          {
            index: "wx8.qq.com",
            file: "file.wx8.qq.com",
            push: "webpush.wx8.qq.com",
          },
          {
            index: "wechat.com",
            file: "file.web.wechat.com",
            push: "webpush.web.wechat.com",
          },
          {
            index: "web2.wechat.com",
            file: "file.web2.wechat.com",
            push: "webpush.web2.wechat.com",
          },
        ],
      }
    end
  end
end
