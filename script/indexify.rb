#!/usr/bin/env ruby

require 'optparse'
require 'dwc-archive'
require 'rest_client'
require 'crack'
require 'pp'

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

res = RestClient.get('http://gnaclr.globalnames.org/classifications?format=json')

res = Crack::JSON.parse(res)

classification =  res['classifications'].select {|c| c['title'].match /eCyphophthalmi/}[0]

pp classification.keys

`wget -P /tmp  #{classification['file_url']}`

dc = DarwinCore.new("/tmp/#{classification['file_url'].split('/')[-1]}")

results = {}

def get_fields(element)
  data = element.fields.inject({}) { |res, f| res[f[:term].split('/')[-1].to_sym] = f[:index]; res }
  data[:id] = element.respond_to?(:coreid) ? element.coreid[:index] : element.id[:index]
  {:fields => data, :path => element.file_path}
end

core = get_fields(dc.core)

extensions = []
dc.extensions.each do |e|
  extensions << get_fields(e)
end

pp dc.core.read

Class Taxon < Struct.new(:id, :current_names, :parent_id, :synonyms, :path); end


