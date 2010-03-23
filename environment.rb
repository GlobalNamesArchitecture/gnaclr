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

require 'sinatra' unless defined?(Sinatra)

configure do
  SiteConfig = OpenStruct.new(
                 :title => 'gnaclr',
                 :author => 'Dmitry Mozzherin',
                 :url_base => 'http://localhost:4567/',
                 :root_path => File.expand_path(File.dirname(__FILE__))
               )

  DataMapper.setup(:default, "sqlite3:///#{File.expand_path(File.dirname(__FILE__))}/#{Sinatra::Base.environment}.db")
  #DataMapper.setup(:default, 'mysql://root:@localhost/gnaclr') 
  # load models
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/models")
  Dir.glob("#{File.dirname(__FILE__)}/lib/*.rb") { |lib|   require File.basename(lib, '.*') }
  Dir.glob("#{File.dirname(__FILE__)}/models/*.rb") { |model| require File.basename(model, '.*') }
end
