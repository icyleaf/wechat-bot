require "bundler/setup"
require "webmock/rspec"
require "rbchat"
require "uri"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def stub_qr_uuid
  stub_request(:get, "#{RBChat::Core::BASE_URL}/jslogin")
    .with(
      headers: { 'User-Agent' => RBChat::Core::USER_AGENT },
      query: { "appid" => "appid", "fun" => "fun" }
    )
    .to_return(body: load_fixture("login.weixin.qq.com/jslogin.txt"), status: 200)
end

def load_fixture(name)
  File.new(File.dirname(__FILE__) + "/fixtures/#{name}")
end
