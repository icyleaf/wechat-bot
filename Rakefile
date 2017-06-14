require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rbchat"
require "awesome_print"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :bot do
  core = RBChat::Core.new
  core.login
  # core.contacts
  core.run
end
