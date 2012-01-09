#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require File.join(File.dirname(__FILE__), 'environment')
require 'resque'

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

error do
  e = request.env['sinatra.error']
  Kernel.puts e.backtrace.join("\n")
  'Application error'
end

helpers do
  def classificaton_file(classification)
    "/files/#{classification.uuid}/#{classification.file_name}"
  end

  def base_url
    return @@base_url if defined? @@base_url
    r = request.env
    port = r['SERVER_PORT'] == "80" ? '' : ":#{r['SERVER_PORT']}"
    @@base_url = "http://#{r['SERVER_NAME']}#{port}"
  end
end

get '/main.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :main
end

# root page
get '/' do
  redirect "/classifications"
end

get '/classifications' do
  params.merge!({:show_revisions => 'true'})
  @cms = Gnaclr::ClassificationMetadataSearcher.new(params)
  @classifications = Classification.all(:order => :updated_at.desc, :limit => @cms.args[:per_page], :offset => ((@cms.args[:page] - 1) * @cms.args[:per_page]))
  @classifications.each {|c| c.format_description} #HACK HACK HACK
  @total_rows = Classification.count
  format = @cms.args[:format]
  if format
    @prepared_data = @cms.prepare_results(@classifications, @total_rows)
    if format == 'json'
      content_type :json
      data = @prepared_data.to_json
      @cms.args[:callback] ? "#{@cms.args[:callback]}(#{data});" : data
    else
      content_type :xml
      @prepared_data.to_xml(:dasherize => false)
    end
  else
    haml :classifications
  end
end

get '/classifications/new' do
  haml :classifications_new
end

post '/classifications' do
  uuid = params[:uuid]
  raise DWCA::UUIDFormatError unless UUID.valid?(uuid) 
  dwca = DWCA.new(uuid, params[:file], SiteConfig.files_path, SiteConfig.root_path)
  data = dwca.process_file
  if data
    classification = Gnaclr.create_classification(uuid, data)
    Resque.enqueue(Gnaclr::SolrIngest, classification.id)
  end
  redirect '/classifications'
end

get '/search' do
  @search_result, args = Gnaclr::Searcher.search_all(params)
  if args[:format] == 'json'
    content_type :json
    data = @search_result.to_json
    args[:callback] ? "#{args[:callback]}(#{data});" : data
  elsif args[:format] == 'xml'
    content_type :xml
    @search_result.to_xml(:dasherize => false)
  else
    haml :search_results
  end
end

get "/classification/:identifier" do
  identifier = params[:identifier]
  params[:show_revisions] = 'true'
  @cms = Gnaclr::ClassificationMetadataSearcher.new(params)
  @classification = UUID.valid?(identifier) ? Classification.first(:uuid => identifier) : Classification.first(:id => identifier.to_i)
  @repository = Gnaclr::Repository.get_repo(@classification.id)
  count = 0
  @commits = Gnaclr::Repository.get_commits(@repository, @classification)
  format = @cms.args[:format]
  if format 
    @prepared_data = @cms.prepare_classification(@classification)
    if format == 'json'
      content_type :json
      data = @prepared_data.to_json
      @cms.args[:callback] ? "#{@cms.args[:callback]}(#{data});" : data
    else
      content_type :xml
      @prepared_data.to_xml(:dasherize => false)
    end
  else
    haml :classification
  end
end

get "/classification_file/:classification_id/:tree_id" do
  @repository = Gnaclr::Repository.get_repo(params[:classification_id])
  blob = @repository.tree(params[:tree_id]).blobs.first
  type, size, file_name = [blob.mime_type, blob.size, blob.name]
  headers(
    'Content-Type'        => type,
    'Content-length'      => size,
    'Content-Disposition' => "attachment; filename=#{file_name}")
  blob.data
end
