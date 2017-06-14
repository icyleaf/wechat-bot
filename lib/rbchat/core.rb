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
      @login_session = {}
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

      @logger.info "用户 [#{@login_session[:user][:nickname]}] 登录成功！"

      runloop
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

      @login_session[:info] = {
        skey: data["error"]["skey"],
        sid: data["error"]["wxsid"],
        uin: data["error"]["wxuin"],
        device_id: "e#{rand.to_s[2..17]}",
        pass_ticket: data["error"]["pass_ticket"],
      }

      @login_session[:base_request] = {
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
          @login_session[:servers] = current_server(server)
        end
      end
      @login_session[:servers] = {
        index: "#{wx_servers[:scheme]}://#{host}#{wx_servers[:path]}",
        file: "#{wx_servers[:scheme]}://#{host}#{wx_servers[:path]}",
        push: "#{wx_servers[:scheme]}://#{host}#{wx_servers[:path]}",
      } unless @current_server

      @login_session[:device_id] = "e#{rand.to_s[2..17]}"
      @login_session
    end

    def sync_messages
      puts @login_session

      url = "#{@login_session[:servers][:index]}/webwxsync?sid=#{@login_session[:info][:sid]}&skey=#{@login_session[:info][:skey]}&pass_ticket=#{@login_session[:info][:pass_ticket]}"
      params = @login_session[:base_request].merge({
        "SyncKey" => @login_session[:sync_key],
        "rr" => unix_timestamp(10)
      })

      r = @session.post(url, json: params) # timeout(write: 10, connect: 10, read: 40).
      @logger.debug "Content: #{r.to_s}"
    end

    def wx_init_web
      url = "#{@login_session[:servers][:index]}/webwxinit?r=#{unix_timestamp(10)}"

      r = @session.post(url, json: @login_session[:base_request])
      data = r.parse(:json)

      @login_session[:user] = {
        username: data["User"]["UserName"],
        nickname: data["User"]["NickName"],
      }

      @login_session[:sync_key] = data["SyncKey"]
      # @login_session[:sync_key] = data["SyncKey"]["List"].map {|k| k.values[-1]}.join("|")
      @login_session[:invite_start_count] = data["InviteStartCount"].to_i

      r
    end

    def wx_status_notify
      url = "#{@login_session[:servers][:index]}/webwxstatusnotify?lang=zh_CN&pass_ticket=#{@login_session[:info][:pass_ticket]}"
      params = @login_session[:base_request].merge({
        "Code"  => 3,
        "FromUserName" => @login_session[:user][:username],
        "ToUserName" => @login_session[:user][:username],
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

    def wx_heartbeat
      url = "#{@login_session[:servers][:push]}/synccheck"
      timestamp = unix_timestamp
      params = @login_session[:info].merge({
        "r" => timestamp,
        "_" => timestamp,
      })

      r = @session.get(url, params: params) # .timeout(write: 10, connect: 10, read: 40)
      data = r.parse(:js)
      @logger.debug "Data: #{data}"

      raise RuntimeException "微信数据同步异常，原始返回内容：#{r.to_s}" if data.nil?

      data["synccheck"]
    end

    def logout
      url = "#{@login_session[:servers][:index]}/webwxlogout"
      params = {
        "redirect" => 1,
        "type"  => 1,
        "skey"  => @login_session[:info][[:skey]]
      }

      r = @session.get(url, params: params)

      @logger.info "用户 [#{@login_session[:user][:nickname]}] 登出成功！"
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

      @login_session = {}
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
