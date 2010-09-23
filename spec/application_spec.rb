require "#{File.dirname(__FILE__)}/spec_helper"

describe 'main application' do
  include Rack::Test::Methods

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
    post('/classifications', :file => Rack::Test::UploadedFile.new(FILE1_1, 'application/gzip'), :uuid => UUID1)
    follow_redirect!
    last_response.body.should include('Leptogastrinae')
    last_response.body.should include('data_v1.tar.gz')
    post('/classifications', :file => Rack::Test::UploadedFile.new(FILE1_2, 'application/gzip'), :uuid => UUID1)
    follow_redirect!
    last_response.body.should include('Leptogastrinae')
    last_response.body.should include('data_v2.tar.gz')
  end

end
