#!/usr/bin/env ruby

require 'optparse'
require 'dwc-archive'
require 'rest_client'
require 'crack'
require File.join(File.dirname(__FILE__), '..', 'lib', 'solr_client')
require 'pp'
require 'nokogiri'

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

def organize_data(data)
  res = []
  data.each_with_index do |value, i|
    key, value = *value
    taxon = {
    :taxon_id => key,
    :current_scientific_name => value.current_name,
    :current_scientific_name_exact => value.current_name_canonical,
    :scientific_name_synonyms => value.synonyms.map { |s| [s.name, s.canonical_name] },
    :common_names => value.vernacular_names.map { |v| v.name },
    :path => value.classification_path,
    :rank => value.rank,
    }
    res << taxon
    if (i+1) % 1000 == 0
      yield res 
      res = []
    end
  end
  yield res
end

solr_client = SolrClient.new
res = RestClient.get('http://localhost:4567/classifications?format=json')
# res = RestClient.get('http://gnaclr.globalnames.org/classifications?format=json')

res = Crack::JSON.parse(res)

# classification =  res['classifications'].select {|c| c['title'].match /eCyphophthalmi/}[0]

res['classifications'].select {|c| c['title'].match(/fungorum/i)}.each do |c|

  dwc_file = "/tmp/#{c['file_url'].split('/')[-1]}"
  FileUtils.rm dwc_file if File.exists? dwc_file
  `wget -P /tmp  #{c['file_url']}`
  dc = DarwinCore.new(dwc_file)

  data = dc.normalize_classification(verbose = true)
  organize_data(data) do |res|
    builder = Nokogiri::XML::Builder.new do |b|
      b.add do
        res.each do |r|
          b.doc_ do 
            b.field(c['id'], :name => 'classification_id')
            b.fields(c['uuid'], :name => 'classification_uuid')
            b.field(r[:taxon_id], :name => 'id')
            b.field(c['id'].to_s + '_' + r[:taxon_id], :name => 'taxon_classification_id')
            b.field(r[:path].join('|'), :name => 'path')
            b.field(r[:rank], :name=> 'rank')
            b.field(r[:current_scientific_namel], :name => 'current_scientific_namel')
            b.field(r[:current_scientific_name_exact], :name => 'current_scientific_name_exact')
            r[:scientific_name_synonyms].each do |name, canonical|
              b.field(name, :name => 'scientific_name_synonym')
              b.field(canonical, :name => 'scientific_name_synonym_exact')
            end
            r[:common_names].each do |name|
              b.field(name, :name => 'canonical_name')
            end
          end
        end
      end
    end
    xml_data = builder.to_xml
    require 'ruby-debug'; debugger
    solr_client.update_with_xml(xml_data, false)
  end


end

