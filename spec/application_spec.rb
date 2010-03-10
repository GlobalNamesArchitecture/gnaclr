require "#{File.dirname(__FILE__)}/spec_helper"
require 'rest_client'

describe 'main application' do
  include Rack::Test::Methods

  def app
    Sinatra::Application.new
  end

  specify 'should show the default index page' do
    get '/'
    last_response.should be_ok
  end
  
  it 'should save classification file' do
    post('/classifications', :multipart => true, :file => File.new(File.join(SiteConfig.root_path, 'spec', 'files', 'data.tar.gz')).read, :agent => 'agent1', :name => 'test', :uuid => UUID.create_v4.guid)
    last_response.should be_ok
  end

end
