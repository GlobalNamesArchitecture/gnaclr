require 'rubygems'
require 'sinatra'
#require 'sinatra/respond_to'
require 'environment'

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
    "/files/#{classification.uuid_hash}/#{classification.file_name}"
  end
end

def get_repo(params)
  classification_id = params[:classification_id]
  classification = Classification.first(:id => classification_id)
  repository = Grit::Repo.new(File.join(SiteConfig.files_path, classification.uuid_hash))
  [classification_id, repository]
end

def search_for(search_term, page, per_page)
  return [[],0] if search_term.strip == ''
  offset = (page - 1) * per_page
  original_search_term = search_term
  search_term = '[[:<:]]' + search_term
  d = repository(:default).adapter
  res = []
  total_rows = 0
  Classification.transaction do
    res = d.select("select SQL_CALC_FOUND_ROWS distinct c.*, '' as authors from classifications c left join author_classifications ac on c.id = ac.classification_id left join authors a on a.id = ac.author_id  where c.uuid = ? or c.title rlike ? or a.first_name rlike ? or a.last_name rlike ? limit ?, ?", original_search_term.strip, search_term, search_term, search_term, offset, per_page )
    total_rows = d.select("select FOUND_ROWS() as count")[0]
  end
  res.each do |c|
    authors = repository(:default).adapter.select("select a.first_name, a.last_name, email from authors a join author_classifications ac on ac.author_id = a.id where ac.classification_id = ?", c.id)
    c.authors = authors
  end
  [res, total_rows]
end

def prepare_data(classifications, total_rows, page, per_page, search_term = nil)
  r = request.env
  url = "http://#{r['HTTP_HOST']}#{r['REQUEST_URI']}"
  total_pages = total_rows/per_page + (total_rows % per_page == 0 ? 0 : 1)
  previous_page = page > 1 ? uri_change_param(url, 'page', page - 1) : nil
  next_page = page < total_pages ? uri_change_param(url, 'page', page + 1) : nil
  cl = []
  classifications.each do |c|
    cl << prepare_classification(c)
  end
  res = { 
    :url => url, :page => page, :per_page => per_page, :total_count => total_rows, 
    :total_pages => total_pages, :previous_page => previous_page, :next_page => next_page,
    :classifications => cl
  }
  res.merge!({:search_term => search_term}) if :search_term.to_s != ''
  res
end

def prepare_classification(classification)
  c = classification
  authors = c.authors.sort_by {|a| a.last_name.downcase}.map { |a| {:first_name => a.first_name, :last_name => a.last_name, :email => a.email} }
  file_url = "http://#{request.env['HTTP_HOST']}/files/#{c.uuid_hash}/#{c.file_name}"
  { 
    :uuid => c.uuid, :file_url => file_url, :title => c.title, 
    :description => c.description, :url => c.url, 
    :citation => c.citation, :authors => authors, 
    :created => c.created_at, :updated => c.updated_at
  }
end

def uri_change_param(uri, param, value)
  return uri unless param
  par_val = "#{param}=#{URI.encode(value.to_s)}"
  uri_parsed = URI.parse(uri)
  return "#{uri}?#{par_val}" unless uri_parsed.query
  new_params = uri_parsed.query.split('&').reject { |q| q.split('=').first == param }
  uri = uri.split('?').first
  "#{uri}?#{new_params.join('&')}&#{par_val}"
end

def darwin_core_archive(file)
  begin
    m = DarwinCore.new(file).metadata
    return m.data ? { :title => m.title, :description => m.description, :authors => m.authors, :url => m.url } : {}
  rescue DarwinCore::Error
    return 
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
  sort_by = params[:sort]
  page = params[:page] ? params[:page].to_i : 1
  per_page = params[:per_page] ? params[:page].to_i : 30
  @classifications = Classification.all(:order => :updated_at.desc, :limit => per_page, :offset => ((page - 1) * per_page))
  @total_rows = Classification.count
  format = params[:format]
  if format && ['json','xml'].include?(format.strip)
    format = format.strip
    @prepared_data = prepare_data(@classifications, @total_rows, page, per_page, @search_term)
    if format == 'json'
      content_type :json
      data = @prepared_data.to_json
      params[:callback] ? "#{params[:callback]}(#{data});" : data
    else
      content_type :xml
      @prepared_data.to_xml
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
  uuid_hash = Classification.uuid_hash(uuid)
  dwca = DWCA.new(uuid_hash, params[:file], SiteConfig.files_path, SiteConfig.root_path)
  data = dwca.process_file
  classification = Classification.first(:uuid => uuid) || Classification.new(:uuid => uuid)
  classification.attributes = { :uuid_hash => uuid_hash, 
                                :citation => data[:citation], 
                                :file_name => data[:file_name], 
                                :title => data[:title], 
                                :description => data[:description], 
                                :url => data[:url]}
  classification.save
  classification.author_classifications.each {|ac| ac.destroy!} 
  authors = []
  data[:authors].each do |a|
    author = Author.first(a) || Author.new(a)
    author.save
    authors << author
  end if data[:authors]
  authors.each { |a| ar = AuthorClassification.new(:author => a, :classification => classification); ar.save }
  classification.author_classifications.reload
  redirect '/classifications'
end

get '/search' do
  page = params[:page] ? params[:page].to_i : 1
  per_page = params[:per_page] ? params[:per_page].to_i : 30
  @search_term = params[:search_term].to_s
  @classifications, @total_rows = search_for(@search_term, page, per_page)
  format = params[:format]
  if format && ['json','xml'].include?(format.strip)
    format = format.strip
    @prepared_data = prepare_data(@classifications, @total_rows, page, per_page, @search_term)
    if format == 'json'
      content_type :json
      data = @prepared_data.to_json
      params[:callback] ? "#{params[:callback]}(#{data});" : data
    else
      content_type :xml
      @prepared_data.to_xml
    end
  else
    haml :classifications
  end
end

get "/history/:classification_id" do
  @classification_id, @repository = get_repo(params)
  @commits = @repository.commits.map { |c| { :message => c.message, :tree_id => c.tree.id, :file_name => c.tree.blobs.first.name } }
  haml :history
end

get "/classification_file/:classification_id/:tree_id" do
  @classification_id, @repository = get_repo(params)
  require 'ruby-debug'
  blob = @repository.tree(params[:tree_id]).blobs.first
  type, size, file_name = [blob.mime_type, blob.size, blob.name]
  headers(
    'Content-Type'        => type,
    'Content-length'      => size,
    'Content-Disposition' => "attachment; filename=#{file_name}")
  blob.data
end
