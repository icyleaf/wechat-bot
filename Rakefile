require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rbchat"
require "awesome_print"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :bot do
  core = RBChat::Core.new
  core.login
end

task :test do
  string = 'window.synccheck={retcode:"1234",selector:"234234"}'

  ap decode string

  ap eval "1231231"
end
