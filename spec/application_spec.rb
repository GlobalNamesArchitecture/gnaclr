require "#{File.dirname(__FILE__)}/spec_helper"

describe 'main application' do
  include Rack::Test::Methods
  before(:all) do
    @uuid = UUID.create_v5("one.example.com", UUID::NameSpace_DNS).guid
  end

  # after(:all)
  #   FileUtils.rm_rf File.join(SiteConfig.files_path, @uuid)  
  # end

  def app
    Sinatra::Application.new
  end

  specify 'should show the default index page' do
    get '/'
    last_response.should be_redirect
  end

  it 'should save classification file keeping different versions' do
    post('/classifications', :file => Rack::Test::UploadedFile.new(File.join(SiteConfig.root_path, 'spec', 'files', 'data_v1.tar.gz'), 'applicaation/gzip'), :uuid => @uuid)
    follow_redirect!
    last_response.body.should include('Leptogastrinae')
    last_response.body.should include('data_v1.tar.gz')
    post('/classifications', :file => Rack::Test::UploadedFile.new(File.join(SiteConfig.root_path, 'spec', 'files', 'data_v2.tar.gz'), 'applicaation/gzip'), :uuid => @uuid)
    follow_redirect!
    last_response.body.should include('Leptogastrinae')
    last_response.body.should include('data_v2.tar.gz')
  end

end
