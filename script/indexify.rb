#!/usr/bin/env ruby

require 'optparse'
require 'sqlite3'
require 'dwc-archive'

OPTIONS = {
  :environment => "development",
  :classification_id => nil,
}

ARGV.options do |opts|
  script_name = File.basename($0)
  opts.banner = "Usage: ruby #{script_name} [options]"

  opts.separator ""

  opts.on("-e", "--environment=name", String,
          "Specifies the environment (test/development/production).",
          "Default: development") { |OPTIONS[:environment]| }

  opts.separator ""

  opts.on("-i", "--identifier=classification_id", String,
          "Specifies the id of classification to index",
          "Default: None") { |OPTIONS[:classification_id]| }

  opts.separator ""

  opts.on("-h", "--help",
          "Show this help message.") { puts opts; exit }

  opts.parse!
end

require 'sinatra'

Sinatra::Base.environment == OPTIONS[:environment].to_sym
Sinatra::Base.set :raise_errors, true
Sinatra::Base.set :logging, false
Sinatra::Application.set :run, false

require File.join(File.dirname(__FILE__), '..', 'application')

classifications = OPTIONS[:classification_id] ? [Classification.first(:id => OPTIONS[:classifications_id])] : Classification.all

classifications.each do |c|
  # puts "%s, %s, %s" % [c.id, c.uuid, c.file_name]
  dc = DarwinCore.new(File.join(SiteConfig.files_path, c.uuid,  c.file_name))
  puts dc.core.fields
end
