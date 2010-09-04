require 'rubygems'
require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'
require 'dm-migrations'
require 'dm-transactions'
require 'will_paginate'
require 'haml'
require 'sass'
require 'ostruct'
require 'digest/sha1'
require 'grit'
require 'yaml'
require 'active_support/all'
require 'dwc-archive'
require 'digest/sha1'
require 'json'

require 'sinatra' unless defined?(Sinatra)

conf = YAML.load(open(File.join(File.dirname(__FILE__), 'database.yml')).read)
root_path = File.expand_path(File.dirname(__FILE__))
configure do
  SiteConfig = OpenStruct.new(
                 :title => 'gnaclr',
                 :author => 'Dmitry Mozzherin',
                 :url_base => 'http://localhost:4567/',
                 :root_path => root_path,
                 :files_path => File.join(root_path, 'public', 'files'),
                 :salt => conf['salt']
               )

  #DataMapper.setup(:default, "sqlite3:///#{File.expand_path(File.dirname(__FILE__))}/#{Sinatra::Base.environment}.db")
  # to see sql during tests uncomment next line
  # DataMapper::Logger.new(STDOUT, :debug)
  DataMapper.setup(:default, "mysql://#{conf['user']}:#{conf['password']}@#{conf['host']}/gnaclr") 
  # load models
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/models")
  Dir.glob("#{File.dirname(__FILE__)}/lib/*.rb") { |lib|   require File.basename(lib, '.*') }
  Dir.glob("#{File.dirname(__FILE__)}/models/*.rb") { |model| require File.basename(model, '.*') }
end
