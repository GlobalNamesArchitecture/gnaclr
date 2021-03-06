# require 'spec/interop/test'
require 'bundler/setup'
require 'crack'
require 'rack/test'
require 'redis'
require 'rspec'
require 'ruby-debug'
require 'rubygems'
require 'sinatra'

# set test environment
Sinatra::Base.set :environment, :test
Sinatra::Base.set :run, false
Sinatra::Base.set :raise_errors, true
Sinatra::Base.set :logging, false

require 'application'
$redis = Redis.new

RSpec.configure do |config|

  unless defined? CONSTANTS_DEFINED
    UUID1 = UUID.create_v5("one.example.com", UUID::NameSpace_DNS).guid
    FILE1_1 = File.join(SiteConfig.root_path, 'spec', 'files', 'data_v1.tar.gz')
    FILE1_2 = File.join(SiteConfig.root_path, 'spec', 'files', 'data_v2.tar.gz')
    CONSTANTS_DEFINED = true
  end 
  
  # reset database before each example is run
  config.before(:each) do 
    DataMapper.auto_migrate!
    $redis.select(0) # selecting resque jobs db
    $redis.flushdb # cleaning up the que
    DWCA.delete_repo_path(File.join(SiteConfig.files_path, UUID1))
  end
end

