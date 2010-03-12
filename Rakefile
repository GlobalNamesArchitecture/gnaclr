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
  task :migrate => [:environment, "git:reset"] do
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
    required_gems = %w{ sinatra rspec rack-test dm-core dm-validations
                        dm-aggregates dm-timestamps dm-pager haml rest-client grit data_objects }
    required_gems.each { |required_gem| system "sudo gem install #{required_gem}" }
  end
end

task :environment do
  require 'environment'
end

namespace :git do
  desc 'Initialize git repository'
  task :init => [:environment] do
    require 'ruby-debug'
    mkdir "public/files" unless FileTest.exists? "public/files"
    unless FileTest.exists? "public/files/.gni"
      Dir.chdir(File.join(File.dirname(__FILE__), "public", "files"))
      `git init`
    end
    puts "Initializing git repository"  
  end
  desc 'Cleaning up git repository'
  task :destroy do
    puts "Removing git repository"
    FileUtils::rm_rf "public/files" if FileTest.exists? "public/files"
  end
  task :reset => [:destroy, :init] do
    puts "Resetting git repository"
  end
end
