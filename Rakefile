require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

require 'wechat_bot'
require 'awesome_print'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc 'Run a sample wechat bot'
task :bot do
  bot = WeChat::Bot.new do
    on :text, "hello" do |m|
      m.reply "Hello, #{m.user.nickname}"
    end
  end

  bot.start
end

task :test do

end
