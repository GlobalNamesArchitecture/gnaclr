require 'rubygems'
require 'sinatra'
require 'spec'
require 'spec/interop/test'
require 'rack/test'

# set test environment
Sinatra::Base.set :environment, :test
Sinatra::Base.set :run, false
Sinatra::Base.set :raise_errors, true
Sinatra::Base.set :logging, false

require 'application'

# establish in-memory database for testing
DataMapper.setup(:default, "sqlite3::memory:")

Spec::Runner.configure do |config|
  UUID1 = UUID.create_v5("one.example.com", UUID::NameSpace_DNS).guid
  FILE1_1 = File.join(SiteConfig.root_path, 'spec', 'files', 'data_v1.tar.gz')
  FILE1_2 = File.join(SiteConfig.root_path, 'spec', 'files', 'data_v2.tar.gz')
  
  # reset database before each example is run
  config.before(:each) do 
    DataMapper.auto_migrate!
    Classification.delete_data_path(UUID1)
  end
end

