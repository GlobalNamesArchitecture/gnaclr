require 'spec/rake/spectask'
require 'escape'

task :default => :test
task :test => :spec

if !defined?(Spec)
  puts "spec targets require RSpec"
else
  desc "Run all examples"
  Spec::Rake::SpecTask.new('spec') do |t|
    t.spec_files = FileList['spec/**/*.rb']
    t.spec_opts = ['-cfs']
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


namespace :gems do
  desc 'Install required gems'
  task :install do
    required_gems = %w{ sinatra rspec rack-test dm-core dm-validations ruby-debug
                        dm-aggregates dm-timestamps dm-pager haml rest-client grit data_objects
                        dm-migrations will_paginate dm-mysql-adapter
                        dm-sqlite-adapter dm-transactions json dwc-archive fastercsv crack
                        optiflag parsley-store
                      }
    required_gems.each { |required_gem| system "gem install #{required_gem}" }
    # required_versioned_gems = [['activesupport','2.3.5']]
    # required_versioned_gems.each { |required_gem, version| system "gem install #{required_gem} -v #{version}" }
  end
end

task :environment do
  require 'environment'
end
