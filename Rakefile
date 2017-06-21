require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

require 'wechat_bot'
require 'awesome_print'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc 'Run a sample wechat bot'
task :bot do
  WeChat::Bot.new do
    configure do |c|
      c.verbose = true
    end

    on :text, "hello" do |m|
      m.reply "Hello, #{m.user.nickname}"
    end

    on :message do |m|
      m.reply "复读机：#{m.message}"
    end
  end.start
end
