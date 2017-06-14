require "http"

module RBChat
  module HTTP
    class Session
      AUTH_URL = "https://login.weixin.qq.com".freeze
      USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.86 Safari/537.36".freeze

      attr_reader :cookies

      def initialize(cookies = nil)
        load_cookies(cookies)
      end

      def get(url, options = {})
        request(:get, url, options)
      end

      def post(url, options = {})
        request(:post, url, options)
      end

      def request(verb, url, options = {})
        url = (url =~ /^http/) ? url : build_uri(url)

        prepare_request(url)
        response = @client.request(verb, url, options)
        update_cookies(response.cookies)

        response
      end

      private

      def prepare_request(url)
        @client = ::HTTP.headers(user_agent: USER_AGENT)

        uri = URI(url)
        unless @cookies.empty?(uri)
          cookies = @cookies.clone
          cookies.cookies.each do |cookie|
            cookies.delete(cookie) if uri.host != cookie.domain
          end

          unless cookies.empty?(uri)
            @client = @client.cookies(@cookies)
          end
        end

        @client
      end

      def update_cookies(cookies)
        return @cookies = cookies if @cookies.empty?

        cookies.cookies.each do |cookie|
          @cookies.add(cookie)
        end
      end

      def load_cookies(cookies)
        @cookies = ::HTTP::CookieJar.new
        return if cookies.nil?

        if cookies.ia_a?(String) && File.exist?(cookies)
          @cookies.load(cookies)
        else
          @cookies.add(cookies)
        end
      end

      def build_uri(uri)
        File.join(AUTH_URL, uri)
      end
    end
  end
end
