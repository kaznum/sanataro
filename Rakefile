# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

Kakeibo3::Application.load_tasks

task :travis do
  ["spec", "cucumber"].each do |cmd|
    puts "Starting to run #{cmd}..."
    system("export DISPLAY=:99.0")
    Rake::Task[cmd].execute   
    raise "rake #{cmd} failed!" unless $?.exitstatus == 0
  end
end

