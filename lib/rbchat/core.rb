require "rqrcode"
require "logger"
require "uri"

module RBChat
  class Core
    QR_FILENAME = "wx_qr.png".freeze
    APP_ID = "wx782c26e4c19acffb"

    def initialize
      @logger = Logger.new(STDOUT)
      @session = HTTP::Session.new

      @is_logged = false
      @login_session = {}
    end

    def login
      return @logger.info("你已经登录") if logged?

      i = 0
      until logged?
        @logger.debug "尝试登录 ..."
        until uuid = qr_uuid
          @logger.info "重新尝试获取登录二维码 ..."
          sleep 1
        end

        qr_code(uuid)

        until logged?
          @logger.debug "检查登录状态 ..."
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

      @logger.info "登录成功！可能需要一点时间加载所需资源"
      init_web_env
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
      @logger.debug "Headers: #{r.headers.to_h}"
      data = r.parse(:xml)

      @login_session[:cookies] = r.cookies
      @login_session[:current] = {
        skey: data["error"]["skey"],
        wxsid: data["error"]["wxsid"],
        wxuin: data["error"]["wxuin"],
        pass_ticket: data["error"]["pass_ticket"],
      }
      @login_session[:base] = {
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

    def init_web_env
      url = "#{@login_session[:servers][:index]}/webwxinit?r=#{unix_timestamp(10)}"

      r = @session.post(url, json: @login_session[:base])
      data = r.parse(:json)

      @logger.debug data

      @login_session[:user] = {

      }
    end

    private

    def logged?
      @is_logged
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
