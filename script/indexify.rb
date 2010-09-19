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
  count = 0
  index = data.each do |key, value|
    count += 1
    puts value.classification_path.size
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
    if count % 10000 == 0
      puts count.to_s + " records injested into solr"
      yield res, count
      res = []
    end
  end
  yield res, (count + 1)
end

def csv_field(a_string, add_quotes = true)
  return '' unless a_string
  if a_string.index(',')
    a_string.gsub!(/"/, '""')
    a_string = '"' + a_string + '"' if add_quotes
  end
  a_string
end

solr_client = SolrClient.new
res = RestClient.get('http://localhost:4567/classifications?format=json')
# res = RestClient.get('http://gnaclr.globalnames.org/classifications?format=json')

res = Crack::JSON.parse(res)

# classification =  res['classifications'].select {|c| c['title'].match /eCyphophthalmi/}[0]

res['classifications'].select{|c| c['title'].match(/fungorum/i)}.each do |c|

  dwc_file = "/tmp/#{c['file_url'].split('/')[-1]}"
  FileUtils.rm dwc_file if File.exists? dwc_file
  `wget -P /tmp  #{c['file_url']}`
  dc = DarwinCore.new(dwc_file)

  data = dc.normalize_classification(verbose = true)
  no_name = data.select {|k, v| v.current_name.nil? || v.current_name.empty?}
  no_name.each {|n| puts n}
  puts 'deleting data from this classification'
  # solr_client.delete("classification_id:#{c['id']}")
  puts 'starting to add new data'
  Dir.entries('/tmp').select {|f| f.match /^solr_dwc_.*csv$/}.each {|f| FileUtils.rm('/tmp/' + f)}
  organize_data(data) do |res, i|
    csv_file = "/tmp/solr_dwc_#{i}.csv"
    puts "creating #{csv_file}"
    f = open(csv_file, 'w')
    f.write("classification_id,classification_uuid,taxon_id,taxon_classification_id,path,rank,current_scientific_name,current_scientific_name_exact,scientific_name_synonym,scientific_name_synonym_exact,common_name\n")
    res.each do |r|
      row = [c['id']]
      row << c['uuid']
      row << csv_field(r[:taxon_id])
      row << csv_field("%s_%s" % [c['id'], r[:taxon_id]]) 
      row << csv_field(r[:path].join('|'))
      row << csv_field(r[:rank])
      row << csv_field(r[:current_scientific_name])
      row << csv_field(r[:current_scientific_name_exact])
      synonyms = []
      synonym_canonicals = []
      common_names = []
      r[:scientific_name_synonyms].each do |name, canonical|
        synonyms << csv_field(name, false)
        synonym_canonicals << canonical
      end
      r[:common_names].each do |name|
        common_names << csv_field(name, false)
      end
      row << '"' + synonyms.join(',') + '"'
      row << '"' + synonym_canonicals.join(',') + '"'
      row << '"' + common_names.join(',') + '"'
      f.write(row.join(',') + "\n")
    end
    f.close
    solr_client.update_with_csv(csv_file)
  end
    # solr_client.update_with_csv(csv_file)
    # organize_data(data) do |res|
    #   builder = Nokogiri::XML::Builder.new do |b|
    #     b.add do
    #       res.each do |r|
    #         b.doc_ do 
    #           b.field(c['id'], :name => 'classification_id')
    #           b.field(c['uuid'], :name => 'classification_uuid')
    #           b.field(r[:taxon_id], :name => 'taxon_id')
    #           b.field(c['id'].to_s + '_' + r[:taxon_id], :name => 'taxon_classification_id')
    #           b.field(r[:path].to_a.join('|'), :name => 'path')
    #           b.field(r[:rank], :name=> 'rank')
    #           b.field(r[:current_scientific_name], :name => 'current_scientific_name')
    #           b.field(r[:current_scientific_name_exact], :name => 'current_scientific_name_exact')
    #           r[:scientific_name_synonyms].each do |name, canonical|
    #             b.field(name, :name => 'scientific_name_synonym')
    #             b.field(canonical, :name => 'scientific_name_synonym_exact')
    #           end
    #           r[:common_names].each do |name|
    #             b.field(name, :name => 'common_name')
    #           end
    #         end
    #       end
    #     end
    #   end
    #   xml_data = builder.to_xml
    #   # open('tmp','w').write(xml_data)
    #   puts 'tick'
    #   solr_client.update_with_xml(xml_data, false)
    # end
    # solr_client.commit

end
