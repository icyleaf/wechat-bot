# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rbchat/version'

Gem::Specification.new do |spec|
  spec.name          = "rbchat"
  spec.version       = RBChat::VERSION
  spec.authors       = ["icyleaf"]
  spec.email         = ["icyleaf.cn@gmail.com"]

  spec.summary       = "wechat for ruby"
  spec.description   = "wechat for ruby"
  spec.homepage      = "https://github.com/icyleaf/rbchat"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock"

  spec.add_dependency "http"
  spec.add_dependency "rqrcode"
  spec.add_dependency "gemoji"
  # spec.add_dependency "os"
end
