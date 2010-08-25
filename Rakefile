require 'spec/rake/spectask'

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

namespace :gems do
  desc 'Install required gems'
  task :install do
    required_gems = %w{ sinatra rspec rack-test dm-core dm-validations ruby-debug
                        dm-aggregates dm-timestamps dm-pager haml rest-client grit data_objects
                        dm-migrations will_paginate dm-mysql-adapter
                        dm-sqlite-adapter dm-transactions json dwc-archive fastercsv
                      }
    required_gems.each { |required_gem| system "gem install #{required_gem}" }
  end
end

task :environment do
  require 'environment'
end
