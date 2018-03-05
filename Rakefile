require 'bundler/gem_tasks'
require 'wechat_bot'
require 'awesome_print'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task :default => [:rubocop, :spec]

desc 'Run a sample wechat bot'
task :bot do
  bot = WeChat::Bot.new do
    configure do |c|
      c.verbose = true
    end

    on :message do |m|
      case m.kind
      when WeChat::Bot::Message::Kind::Text
        m.reply m.message
      when WeChat::Bot::Message::Kind::Emoticon
        if m.media_id.to_s.empty?
          m.reply "微信商店的表情哪有私藏的好用！"
        else
          m.reply m.media_id, type: :emoticon
        end
      when WeChat::Bot::Message::Kind::ShareCard
        m.reply "标题：#{m.meta_data.title}\n描述：#{m.meta_data.description}\n#{m.meta_data.link}"
      when WeChat::Bot::Message::Kind::System
        m.reply "系统消息：#{m.message}"
      else
        m.reply "[#{m.kind}]消息：#{m.message}"
      end
    end
  end

  bot.start
end
