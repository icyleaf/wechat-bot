# wechat-bot

[![Build Status](https://img.shields.io/circleci/project/github/icyleaf/wechat-bot.svg?style=flat)](https://circleci.com/gh/icyleaf/wechat-bot)
[![Code Climate](https://img.shields.io/codeclimate/github/icyleaf/wechat-bot.svg?style=flat)](https://codeclimate.com/github/icyleaf/wechat-bot)
[![Inline docs](http://inch-ci.org/github/icyleaf/wechat-bot.svg?style=flat)](https://inch-ci.org/github/icyleaf/wechat-bot)
[![Gem version](https://img.shields.io/gem/v/wechat-bot.svg?style=flat)](https://rubygems.org/gems/wechat-bot)
[![License](https://img.shields.io/badge/license-MIT-red.svg?style=flat)](LICENSE.txt)

微信机器人 Ruby 版本。

## 快速上手

```ruby
require 'wechat-bot'

bot = Wechat::Bot.new do
  on :message, "ping" do |message|
    message.reply "PONG"
  end
end

bot.start
```
