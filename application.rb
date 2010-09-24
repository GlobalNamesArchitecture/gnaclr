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
  page = params[:page] ? params[:page].to_i : 1
  per_page = params[:per_page] ? params[:page].to_i : 30
  @classifications = Classification.all(:order => :updated_at.desc, :limit => per_page, :offset => ((page - 1) * per_page))
  @total_rows = Classification.count
  format = params[:format] ? params[:format].strip : nil
  if format && ['json','xml'].include?(format)
    @prepared_data = prepare_data(@classifications, @total_rows, page, per_page, nil, true)
    if format == 'json'
      content_type :json
      data = @prepared_data.to_json
      params[:callback] ? "#{params[:callback]}(#{data});" : data
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
  s = Gnaclr::Searcher.new(params)
  if params[:search_term]
    @search_result = s.search
    format = s.args[:format]
    if format == 'json'
      content_type :json
      data = @search_result.to_json
      params[:callback] ? "#{params[:callback]}(#{data});" : data
    elsif format == 'xml'
      content_type :xml
      @search_result.to_xml(:dasherize => false)
    else
      haml :search_result
    end
  end
end

get "/classification/:identifier" do
  identifier = params[:identifier]
  @classification = UUID.valid?(identifier) ? Classification.first(:uuid => identifier) : Classification.first(:id => identifier.to_i)
  @repository = Gnaclr::Repository.get_repo(@classification.id)
  count = 0
  @commits = Gnaclr::Repository.get_commits(@repository, @classification)
  format = params[:format] ? params[:format].strip : nil
  if format && ['json','xml'].include?(format)
    @prepared_data = prepare_classification(@classification, true)
    if format == 'json'
      content_type :json
      data = @prepared_data.to_json
      params[:callback] ? "#{params[:callback]}(#{data});" : data
    else
      content_type :xml
      @prepared_data.to_xml(:dasherize => false)
    end
  else
    haml :classification
  end
end

get "/classification_file/:classification_id/:tree_id" do
  @repository = get_repo(params[:classification_id])
  blob = @repository.tree(params[:tree_id]).blobs.first
  type, size, file_name = [blob.mime_type, blob.size, blob.name]
  headers(
    'Content-Type'        => type,
    'Content-length'      => size,
    'Content-Disposition' => "attachment; filename=#{file_name}")
  blob.data
end
