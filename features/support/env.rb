require File.join(File.dirname(__FILE__), %w{.. .. spec spec_helper})

require 'capybara'
require 'capybara/cucumber'

Capybara.app = Sinatra::Application.new

class GnaclrWorld
  def app
    Sinatra::Application
  end

  include Capybara
  include Rack::Test::Methods
  include Spec::Expectations
  include Spec::Matchers
end

World do
  GnaclrWorld.new
end

Before do
  DataMapper.auto_migrate!
  (1...2).each do |num|
    FileUtils.rm_rf File.join(SiteConfig.files_path, "00000000-0000-0000-0000-000000000000".gsub("0", num.to_s))
  end
end
