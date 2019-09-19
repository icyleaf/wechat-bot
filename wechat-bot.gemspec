# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wechat/bot/version'

Gem::Specification.new do |spec|
  spec.name          = "wechat-bot"
  spec.version       = WeChat::Bot::VERSION
  spec.authors       = ["icyleaf"]
  spec.email         = ["icyleaf.cn@gmail.com"]

  spec.summary       = "WeChat Bot for Ruby"
  spec.description   = "WeChat Bot for Ruby with personal account"
  spec.homepage      = "https://github.com/icyleaf/wechat-bot"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.1.0"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 0.57.2"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "awesome_print"

  spec.add_dependency "colorize", "~> 0.8.1"
  spec.add_dependency "http", ">= 2.2.2", "< 4.2.0"
  spec.add_dependency "rqrcode", ">= 0.10.1", "< 1.2.0"
  spec.add_dependency "multi_xml", "~> 0.6.0"
  # spec.add_dependency "representable", "~> 3.0.4"
  # spec.add_dependency "roxml", "~> 3.3.1"
  # spec.add_dependency "gemoji"
end
