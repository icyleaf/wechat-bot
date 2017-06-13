require "rqrcode"
require "http"
require "gemoji"
require "logger"
require "uri"

module RBChat
  class Core
    BASE_URL = "https://login.weixin.qq.com".freeze
    QR_FILENAME = "wx_qr.png".freeze
    USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.86 Safari/537.36".freeze
    APP_ID = "wx782c26e4c19acffb"

    def initialize
      @logger = Logger.new(STDOUT)
      @is_logged = false
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
          @logger.debug status
          @logger.debug status_data
          case status
          when :logged
            @is_logged = true
            store_login_data(status_data)
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
    end

    def qr_uuid
      params = {
        "appid" => APP_ID,
        "fun" => "new",
        "lang" => "zh_CN",
        "_" => unix_timestamp,
      }

      @logger.info "获取登录唯一标识 ..."
      r = request(:get, "jslogin", params).to_s
      data = js_to_hash(r)

      return data["uuid"] if data["code"] == 200
    end

    def qr_code(uuid, renderer = "ansi")
      @logger.info "获取登录用扫描二维码 ... "
      url = build_uri("l/#{uuid}")
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

      r = request(:get, "cgi-bin/mmwebwx-bin/login", params).to_s

      data = js_to_hash(r)
      status = case data["code"]
      when 200 then :logged
      when 201 then :scaned
      when 408 then :waiting
      else          :timeout
      end

      [status, data]
    end

    def store_login_data(data)
      r = request(:get, data["redirect_uri"]).to_s
      wx_servers[:servers].each do |server|
        host = URI.parse(data["redirect_uri"]).host
        if host == server[:index]
          @current_server = current_server(server)
        end
      end
    end

    private

    def request(method, uri, params = nil, post_type = :form)
      url = (uri =~ /^http/) ? uri : build_uri(uri)
      client = HTTP.headers(user_agent: USER_AGENT)

      @logger.debug "URL: [#{post_type}] #{url}"
      @logger.debug "Params: #{params}"

      r = case method
      when :get
      client.get(url, params: params ? params : {})
      when :post
      client.post(url, post_type => form)
      else
        raise StandardError, "Unkown request method, only get/post"
      end

      @logger.debug "Content: #{r}"

      r
    end

    def build_uri(uri)
      File.join(BASE_URL, uri)
    end

    def logged?
      @is_logged
    end

    def unix_timestamp
      Time.now.strftime('%s%3N')
    end

    def current_server(servers)
      servers.each_with_object do |(name, host), obj|
        obj[name] = "#{wx_servers[:scheme]}://#{host}#{path}"
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

    def js_to_hash(string)
      string.split("window.").each_with_object({}) do |item, obj|
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
