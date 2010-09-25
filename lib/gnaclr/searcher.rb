module Gnaclr
  class Searcher

    def self.search_all(params)
      sci = Gnaclr::Searcher.new(ScientificNameSearcher.new(params))
      vern = Gnaclr::Searcher.new(VernacularNameSearcher.new(params))
      meta = Gnaclr::Searcher.new(ClassificationMetadataSearcher.new(params))
      sci_res = sci.search
      vern_res = vern.search
      meta_res = meta.search
      [{:search_term => sci.args[:search_term], :scientific_name_search => sci_res, :vernacular_name_search => vern_res, :classification_metadata_search => meta_res }, sci.args]
    end

    def initialize(engine, params = nil)
      Raise "Not a searcher" unless engine.is_a? SearcherAbstract
      @engine = engine
      self.args = params if params
    end
   
    def args=(params)
      @engine.args=(params)
    end

    def args
      @engine.args
    end

    def search
      @engine.search
    end
    
    def search_raw
      @engine.search_raw
    end

  end

  class SearcherAbstract
    attr_reader :args
    
    def initialize(params = {})
      self.args = params
      @solr_client = SolrClient.new
    end
    
    def args=(params)
      page = params[:page] ? params[:page].to_i : 1
      per_page = params[:per_page] ? params[:per_page].to_i : 30
      search_term = params[:search_term].to_s
      format = params[:format] ? params[:format].strip : nil
      format = ['json','xml'].include?(format) ? format : nil
      callback = params[:callback] ? params[:callback].strip : nil
      show_revisions = params[:show_revisions] && params[:show_revisions].strip == 'true' ? true : false
      @args = {
        :page => page, 
        :per_page => per_page, 
        :search_term => search_term, 
        :format => format, 
        :show_revisions => show_revisions,
        :callback => callback
      }
    end

    def search
      res, total = search_raw
      prepare_results(res, total) 
    end
    
    def prepare_results(classifications, total_rows)
      total_pages = total_rows/@args[:per_page] + (total_rows % @args[:per_page] == 0 ? 0 : 1)
      previous_page = @args[:page] > 1 ? @args[:page] - 1 : nil
      next_page = @args[:page] < total_pages ? @args[:page] + 1 : nil
      cl = []
      classifications.each do |c|
        cl << prepare_classification(c)
      end
      res = {
        :page => @args[:page], :per_page => @args[:per_page], :total_count => total_rows,
        :total_pages => total_pages, :previous_page => previous_page, :next_page => next_page,
        :classifications => cl
      }
      res
    end  

    def search_raw
      return [[],0] if @args[:search_term].empty?
    end
    
    private
    def classification_hash(classification)
      c = classification
      authors = c.authors.sort_by {|a| a.last_name.downcase}.map { |a| {:first_name => a.first_name, :last_name => a.last_name, :email => a.email} }
      file_url = "/files/#{c.uuid}/#{c.file_name}"
      res = {
        :id => c.id, :uuid => c.uuid, :file_url => file_url,
        :title => c.title, :description => c.description,
        :url => c.url, :citation => c.citation, :authors => authors,
        :created => c.created_at, :updated => c.updated_at
      }
      if @args[:show_revisions]
        repository = Gnaclr::Repository.get_repo(classification.id)
        commits = Gnaclr::Repository.get_commits(repository, classification)
        res.merge!({:revisions => commits})
      end
      res
    end
    
  end


  class ClassificationMetadataSearcher < SearcherAbstract

    def search_raw
      super
      offset = (@args[:page] - 1) * @args[:per_page]
      original_search_term = @args[:search_term].strip
      search_term = '[[:<:]]' + @args[:search_term].strip
      d = repository(:default).adapter
      res = []
      total_rows = 0
      Classification.transaction do
        res = d.select("select SQL_CALC_FOUND_ROWS distinct c.*, '' as authors from classifications c left join author_classifications ac on c.id = ac.classification_id left join authors a on a.id = ac.author_id where c.uuid = ? or c.title rlike ? or a.first_name rlike ? or a.last_name rlike ? limit ?, ?", original_search_term, search_term, search_term, search_term, offset, @args[:per_page] )
        total_rows = d.select("select FOUND_ROWS() as count")[0]
      end
      res.each do |c|
        authors = repository(:default).adapter.select("select a.first_name, a.last_name, email from authors a join author_classifications ac on ac.author_id = a.id where ac.classification_id = ?", c.id)
        c.authors = authors
      end
      [res, total_rows]
    end

    def prepare_classification(classification)
      classification_hash(classification)
    end
  end

  class ScientificNameSearcher < SearcherAbstract
    def search_raw
      super
      query = %Q|current_scientific_name_exact:"#{@args[:search_term]}" OR scientific_name_synonym_exact:"#{@args[:search_term]}"|
      res = @solr_client.search(query, @args)
      total = res[:response][:numFound]
      [res[:response][:docs], total]
    end

    def prepare_classification(classification)
      c = Classification.first(:id => classification[:classification_id][0])
      res = classification_hash(c)
      found_as = (@args[:search_term].strip == classification[:current_scientific_name_exact][0].strip) ? 'current_name' : 'synonym'
      res.merge!({
        :rank => classification[:rank][0], 
        :path => classification[:path][0],
        :vernacular_names => classification[:common_name],
        :current_name => classification[:current_scientific_name][0],
        :synonyms => classification[:current_name_synonym],
        :found_as => found_as
      })
    end

  end

  class VernacularNameSearcher < SearcherAbstract
    def search_raw
      super
      query = %Q|common_name_exact:"#{@args[:search_term]}"|
      res = @solr_client.search(query, @args)
      total = res[:response][:numFound]
      [res[:response][:docs], total]
    end

    def prepare_classification(classification)
      c = Classification.first(:id => classification[:classification_id][0])
      res = classification_hash(c)
      found_as = "vernacular_name"
      res.merge!({
        :rank => classification[:rank][0], 
        :path => classification[:path][0],
        :vernacular_names => classification[:common_name],
        :current_name => classification[:current_scientific_name][0],
        :synonyms => classification[:current_name_synonym],
        :found_as => found_as
      })
    end
  end
end
