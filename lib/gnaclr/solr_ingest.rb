require 'dwc-archive'
require 'rest_client'

module Gnaclr

  unless defined? GNACLR_DEFINED
    TEMP_DIR = "/tmp"
    SOLR_URL = "http://localhost:8983/solr"
    ROWS_PER_FILE = 10_000
    GNACLR_DEFINED = true
  end

  class SolrIngest
    @queue = :solr_ingest

    def self.perform(classification_id, solr_url = SOLR_URL)
      classification = Classification.first(:id => classification_id)    
      raise RuntimeError, "No classification with id #{classification_id}" unless classification
      si = SolrIngest.new(classification, solr_url)
      si.ingest
    end

    def initialize(classification, solr_url = SOLR_URL)
      raise RuntimeError, "Not a classification" unless classification.is_a? Classification
      @classification = classification
      @solr_client = SolrClient.new(solr_url)
      @temp_file = "solr_" + @classification.uuid + "_"
    end

    def ingest
      @dwca = DarwinCore.new(@classification.file_path)
      data = @dwca.normalize_classification
      @solr_client.delete("classification_id:#{@classification.id}")
      delete_solr_csv_files
      organize_data(data) do |solr_data, i|
        csv_file = create_solr_csv_file(solr_data, i)
        @solr_client.update_with_csv(csv_file)
      end
    end

    private
    def create_solr_csv_file(solr_data, i)
      csv_file = File.join(TEMP_DIR, "#{@temp_file}#{i}")
      f = open(csv_file, 'w')
      f.write("classification_id,classification_uuid,taxon_id,taxon_classification_id,path,rank,current_scientific_name,current_scientific_name_exact,scientific_name_synonym,scientific_name_synonym_exact,common_name\n")
      solr_data.each do |r|
        row = [@classification.id]
        row << @classification.uuid
        row << csv_field(r[:taxon_id])
        row << csv_field([@classification.id, r[:taxon_id]].join("_")) 
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
      csv_file
    end

    def delete_solr_csv_files
      Dir.entries(TEMP_DIR).select {|f| f.match /^#{@temp_file}/}.each {|f| FileUtils.rm(File.join(TEMP_DIR, f))}
    end

    def organize_data(data)
      res = []
      count = 0
      index = data.each do |key, value|
        count += 1
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
        if count % ROWS_PER_FILE == 0
          # puts count.to_s + " records injested into solr"
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

        
  end
  
end
