require "bundler/setup"
require "webmock/rspec"
require "wechat/bot"
require "uri"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def load_fixture(name)
  File.new(File.dirname(__FILE__) + "/fixtures/api/#{name}")
end

def load_content(name)
  load_fixture(name).readlines.join("\n")
end
