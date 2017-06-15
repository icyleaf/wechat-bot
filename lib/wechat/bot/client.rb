require "rqrcode"
require "logger"
require "uri"

module WeChat::Bot
  class Client
    def initialize(bot)
      @bot = bot
      clone!
    end

    def run
      while true
        return @logger.info "尚未登录" unless logged? || alive?
        sleep 1
      end
    rescue Interrupt
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
      login_loading
      update_notice_status

      @logger.info "用户 [#{@store[:user][:nickname]}] 登录成功！"

      runloop
    rescue Interrupt
      @logger.info "你使用 Ctrl + C 终止了运行"
      logout if logged? && alive?
    end

    def qr_uuid
      params = {
        "appid" => @bot.config.app_id,
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
      @bot.config.servers.each do |server|
        if host == server[:index]
          @store[:servers] = build_server(server)
          break
        end
      end

      raise RuntimeError, "没有匹配到对于的微信服务器: #{host}" unless @store[:servers]

      r
    end

    def login_loading
      url = "#{@store[:servers][:index]}/webwxinit?r=#{unix_timestamp}"

      r = @session.post(url, json: @store[:base_request])
      data = r.parse(:json)

      @store[:user] = {
        username: data["User"]["UserName"],
        nickname: data["User"]["NickName"],
      }

      @store[:info][:sync_key] = build_sync_key(data["SyncKey"])
      @store[:invite_start_count] = data["InviteStartCount"].to_i
      @store[:sync_key] = data["SyncKey"]

      @store[:contacts] = data["ContactList"]
      r
    end

    def update_notice_status
      url = "#{@store[:servers][:index]}/webwxstatusnotify?lang=zh_CN&pass_ticket=#{@store[:info][:pass_ticket]}"
      params = @store[:base_request].merge({
        "Code"  => 3,
        "FromUserName" => @store[:user][:username],
        "ToUserName" => @store[:user][:username],
        "ClientMsgId" => unix_timestamp
      })

      r = @session.post(url, json: params)
      r
    end

    def runloop
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
                sync_messages
              end
            elsif status[:retcode] == "1100"
              @logger.info("账户在手机上进行登出操作")
              @is_alive = false
              break
            elsif [ "1101", "1102" ].include?(status[:retcode])
              @logger.info("账户在手机上进行登出或在其他地方进行登录操作操作")
              @is_alive = false
              break
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

    def sync_check
      url = "#{@store[:servers][:push]}/synccheck"
      params = {
        "r" => unix_timestamp,
        "skey" => @store[:info][:skey],
        "sid" => @store[:info][:sid],
        "uin" => @store[:info][:uin],
        "deviceid" => @store[:info][:device_id],
        "synckey" => @store[:info][:sync_key],
        "_" => unix_timestamp,
      }

      r = @session.get(url, params: params, timeout: [10, 60])
      data = r.parse(:js)

      # raise RuntimeException "微信数据同步异常，原始返回内容：#{r.to_s}" if data.nil?

      @logger.debug "HeartBeat: #{r.to_s}"
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
        "rr" => "-#{unix_timestamp}"
      })

      r = @session.post(url, json: params, timeout: [10, 60])
      data = r.parse(:json)

      @store[:info][:sync_key] = build_sync_key(data["SyncKey"])
      @store[:sync_key] = data["SyncKey"]

      r
    end

    # 获取当前会话列表
    def contacts
      query = {
        "r" => unix_timestamp,
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
      clone!
    end

    def logged?
      @is_logged
    end

    def alive?
      @is_alive
    end

    private

    def default_logger
      @logger = Logger.new($stdout)
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "#{severity}\t[#{datetime.strftime("%Y-%m-%d %H:%M:%S.%2N")}]: #{msg}\n"
      end
    end

    def unix_timestamp
      Time.now.strftime("%s%3N")
    end

    def build_server(servers)
      server_scheme = "https"
      server_path = "/cgi-bin/mmwebwx-bin"
      servers.each_with_object({}) do |(name, host), obj|
        obj[name] = "#{server_scheme}://#{host}#{server_path}"
      end
    end

    def build_sync_key(data)
      data["List"].map {|i| i.values.join("_") }.join("|")
    end

    def clone!
      default_logger
      @session = HTTP::Session.new(@bot.config)
      @is_logged = @is_alive = false
      @store = {}
    end
  end
end
