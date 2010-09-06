require 'rubygems'
require 'rest_client'
require 'nokogiri'
require 'uri'

class SolrClient
  
  attr_reader :url
  
  alias :create :update

  def initialize(solr_url)
    @url = solr_url
    @url_update = @url + "/update"
    @url_search = @url + '/select/?version=2.2&indent=on&wt=json&q='
  end

  def commit
    post('<commit />')
  end

  def update(ruby_data, to_commit = true)
    xml_data = build_solr_xml(ruby_data)
    post(xml_data)
    commit if to_commit
  end

  def delete(query, to_commit = true)
    post('<delete><query>#{query}</query></delete>')
    commit if to_commit
  end

  def delete_all
    post('<delete><query>*:*</query></delete>')
    commit
  end

  def search(query, options = {})
    get(query, options)
  end
  
private
  def post(xml_data, url = nil)
    url ||= @url_update
    RestClient.post url, xml_data, :content_type => :xml, :accept => :xml
  end

  def get(query, options)
    url = @url_search 
    url << URI.encode(%Q[{!lucene} #{query} AND published:1 AND supercedure_id:0])
    limit  = options[:per_page] ? options[:per_page].to_i : 10
    page = options[:page] ? options[:page].to_i : 1
    offset = (page - 1) * limit
    url << '&start=' << URI.encode(offset.to_s)
    url << '&rows='  << URI.encode(limit.to_s)
    RestClient.get url, {:accept => :json}
  end

  # Takes an array of hashes. Each hash has only string or array of strings values. Array is converted into an xml ready
  # for either create or update methods of Solr API  #
  # See the solr_api library spec for some examples.
  def build_solr_xml(ruby_data)
    builder = Nokogiri::XML::Builder.new do |sxml|
      sxml.add do 
        ruby_data = [ruby_data] if ruby_data.class != Array
        ruby_data.each do |data|
          sxml.doc_ do
            data.keys.each do |key|
              data[key] = [data[key]] if data[key].class != Array
              data[key].each do |val|
                sxml.field(val, :name => key.to_s) 
              end
            end
          end
        end
      end
    end
    builder.to_xml
  end  

end
