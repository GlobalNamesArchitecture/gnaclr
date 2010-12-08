require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'
require 'escape'
require 'resque'
require 'resque/tasks'

task :default => :test
task :test => :spec

if !defined?(RSpec)
  puts "spec targets require RSpec"
else
  desc "Run all examples"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = 'spec/**/*.rb'
    t.rspec_opts = ['-cfs']
  end
end

namespace :resque do
  task :stop_workers => :environment do
    desc "Finds and quits all running workers"
    puts "Quitting resque workers"
    pids = Array.new
    Resque.workers.each do |worker|
      pids.concat(worker.worker_pids)
    end
    unless pids.empty? 
      system("kill -QUIT #{pids.join(' ')}")
      god_pid = "/var/run/god/resque-1.10.0.pid" 
      FileUtils.rm god_pid if File.exists? god_pid
    end
  end
end

namespace :db do
  desc 'Auto-migrate the database (destroys data)'
  task :migrate => :environment do
    `rm -rf #{File.join(SiteConfig.files_path, "*")}`
    DataMapper.auto_migrate!
  end

  desc 'Auto-upgrade the database (preserves data)'
  task :upgrade => :environment do
    DataMapper.auto_upgrade!
  end
end

namespace :solr do
  def run_command(command_type)
    port = SiteConfig.solr_url.match(/^.*:(\d+)/)[1]
    command = [File.join(SiteConfig.root_path, 'script', 'solr'), command_type, '--', '-p', port]
    command += ['-s', SiteConfig.solr_dir] if SiteConfig.solr_dir
    system(Escape.shell_command(command))
  end

  desc 'start solr server instance in the background'
  task :start => :environment do
    puts "** Starting Bakground Solr instance **"
    run_command('start')
  end

  desc 'start solr server instance in the foreground'
  task :run => :environment do
    puts "** Starting Foreground Solr instance **"
    run_command('run')
  end

  desc 'stop solr instance'
  task :stop => :environment do
    puts "** Stopping Background Solr instance **"
    system(Escape.shell_command([File.join(SiteConfig.root_path, 'script', 'solr'), 'stop']))
  end
end

task :environment do
  require 'environment'
end
