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

# classification =  res['classifications'].select {|c| c['title'].match /eCyphophthalmi/}[0]

res['classifications'].select {|c| c['title'].match(/fungorum/i)}.each do |c|

  dwc_file = "/tmp/#{c['file_url'].split('/')[-1]}"
  FileUtils.rm dwc_file if File.exists? dwc_file
  `wget -P /tmp  #{c['file_url']}`
  dc = DarwinCore.new(dwc_file)

  res = dc.normalize_classification(verbose = true)
  require 'ruby-debug'; debugger

  puts "'%s' is injested" %  c['title']
end
