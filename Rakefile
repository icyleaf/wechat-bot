require 'bundler/gem_tasks'
require 'rdoc/task'

require 'wechat_bot'
require 'awesome_print'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc 'Run a sample wechat bot'
task :bot do
  bot = WeChat::Bot.new
  bot.start
end

task :test do
  aa(:key)
  aa("key")
  aa(:key, "adfasdf")
  aa("key", "value")
  aa(key: "value")
  aa(key: "value", key2: "value2")
end


def aa(*args)
  ap args
end

def bb(**args)
  ap args
end
