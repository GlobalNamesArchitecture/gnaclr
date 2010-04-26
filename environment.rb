require 'rubygems'
require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'
require 'dm-pager'
require 'haml'
require 'sass'
require 'ostruct'
require 'digest/sha1'
require 'ruby-debug'
require 'grit'
require 'yaml'
require 'dwc-archive'

require 'sinatra' unless defined?(Sinatra)

conf = YAML.load(open(File.join(File.dirname(__FILE__), 'database.yml')).read)

configure do
  SiteConfig = OpenStruct.new(
                 :title => 'gnaclr',
                 :author => 'Dmitry Mozzherin',
                 :url_base => 'http://localhost:4567/',
                 :root_path => File.expand_path(File.dirname(__FILE__))
               )

  #DataMapper.setup(:default, "sqlite3:///#{File.expand_path(File.dirname(__FILE__))}/#{Sinatra::Base.environment}.db")
  DataMapper.setup(:default, "mysql://#{conf['user']}:#{conf['password']}@#{conf['host']}/gnaclr") 
  # load models
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/models")
  Dir.glob("#{File.dirname(__FILE__)}/lib/*.rb") { |lib|   require File.basename(lib, '.*') }
  Dir.glob("#{File.dirname(__FILE__)}/models/*.rb") { |model| require File.basename(model, '.*') }
end
