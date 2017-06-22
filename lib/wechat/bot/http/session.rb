require "http"

module WeChat::Bot
  module HTTP
    # 可保存 Cookies 的 HTTP 请求类
    #
    # 简单实现 Python 版本 {http://docs.python-requests.org/zh_CN/latest/user/advanced.html#session-objects requests.Session()}
    class Session
      # @return [HTTP::CookieJar]
      attr_reader :cookies

      def initialize(bot)
        @bot = bot

        load_cookies(@bot.config.cookies)
      end

      # @return [HTTP::Response]
      def get(url, options = {})
        request(:get, url, options)
      end

      # @return [HTTP::Response]
      def post(url, options = {})
        request(:post, url, options)
      end

      # @return [HTTP::Response]
      def put(url, options = {})
        request(:put, url, options)
      end

      # @return [HTTP::Response]
      def delete(url, options = {})
        request(:delete, url, options)
      end

      # @return [HTTP::Response]
      def request(verb, url, options = {})
        prepare_request(url)

        if options[:timeout]
          connect_timeout, read_timeout = options.delete(:timeout)
          @client = @client.timeout(connect: connect_timeout, read: read_timeout)
        end

        response = @client.request(verb, url, options)
        update_cookies(response.cookies)

        response
      end

      private

      # 组装 request 基础请求参数
      #
      #  - 设置 User-Agent
      #  - 设置 Cooklies
      #
      # @api private
      # @param [String] url
      # @return [HTTP::Request]
      def prepare_request(url)
        @client = ::HTTP.headers(user_agent: @bot.config.user_agent, "Range" => "bytes=0-")
        return @client if @cookies.nil?
        return @client = @client.cookies(@cookies)

        # TODO: 优化处理同一顶级域名的 cookies
        # uri = URI(url)
        # unless @cookies.empty?(uri)
        #   cookies = @cookies.clone
        #   cookies.cookies.each do |cookie|
        #     cookies.delete(cookie) if uri.host != cookie.domain
        #   end

        #   unless cookies.empty?(uri)
        #     @client = @client.cookies(@cookies)
        #   end
        # end

        # @client
      end

      # 加载外部的 Cookies 数据
      #
      # @api private
      # @param [String, HTTP::CooieJar] cookies
      # @return [void]
      def load_cookies(cookies)
        @cookies = ::HTTP::CookieJar.new
        return if cookies.nil?

        if cookies.is_a?(String)
          @cookies.load(cookies) if File.exist?(cookies)
        elsif
          @cookies.add(cookies)
        end
      end

      # 请求后更新存储的 Cookies 数据
      #
      # @api private
      # @param [String, HTTP::CooieJar] cookies
      # @return [void]
      def update_cookies(cookies)
        return @cookies = cookies if @cookies.nil? || @cookies.empty?

        cookies.cookies.each do |cookie|
          @cookies.add(cookie)
        end
      end
    end
  end
end
