require 'bundler/setup'
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

environment = ENV["RACK_ENV"] || ENV["RAILS_ENV"]
environment = (environment && ["production", "test", "development"].include?(environment.downcase)) ? environment.downcase.to_sym : :development

Sinatra::Base.environment = environment


root_path = File.expand_path(File.dirname(__FILE__))
conf = YAML.load(open(File.join(root_path, 'config.yml')).read)[Sinatra::Base.environment.to_s]
configure do
  SiteConfig = OpenStruct.new(
                 :title => 'gnaclr',
                 :author => 'Dmitry Mozzherin',
                 :url_base => conf['url_base'],
                 :root_path => root_path,
                 :files_path => File.join(root_path, 'public', 'files'),
                 :salt => conf['salt'],
                 :solr_url => conf['solr_url'],
                 :solr_dir => Sinatra::Base.environment == 'production' ? nil : File.join(root_path, 'solr', 'solr')
               )

  # to see sql during tests uncomment next line
  # DataMapper::Logger.new(STDOUT, :debug)
  DataMapper.setup(:default, "mysql://#{conf['user']}:#{conf['password']}@#{conf['host']}/#{conf['database']}") 

  # load models
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib', 'gnaclr'))
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'models'))
  Dir.glob(File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')) { |lib|   require File.basename(lib, '.*') }
  Dir.glob(File.join(File.dirname(__FILE__), 'models', '*.rb')) { |model| require File.basename(model, '.*') }
end
