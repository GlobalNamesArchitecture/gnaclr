require 'rubygems'
require 'sinatra'
require 'spec'
require 'spec/interop/test'
require 'rack/test'
require 'crack'
require 'ruby-debug'

# set test environment
Sinatra::Base.set :environment, :test
Sinatra::Base.set :run, false
Sinatra::Base.set :raise_errors, true
Sinatra::Base.set :logging, false

require 'application'

Spec::Runner.configure do |config|

  unless defined? CONSTANTS_DEFINED
    UUID1 = UUID.create_v5("one.example.com", UUID::NameSpace_DNS).guid
    FILE1_1 = File.join(SiteConfig.root_path, 'spec', 'files', 'data_v1.tar.gz')
    FILE1_2 = File.join(SiteConfig.root_path, 'spec', 'files', 'data_v2.tar.gz')
    CONSTANTS_DEFINED = true
  end 
  
  # reset database before each example is run
  config.before(:each) do 
    DataMapper.auto_migrate!
    DWCA.delete_repo_path(File.join(SiteConfig.files_path, UUID1))
  end
end

