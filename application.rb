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
  return [] if search_term.strip == ''
  offset = (page - 1) * per_page
  search_term = '[[:<:]]' + search_term
  res = repository(:default).adapter.select("select distinct c.*, '' as authors from classifications c left join author_classifications ac on c.id = ac.classification_id left join authors a on a.id = ac.author_id  where c.title rlike ? or a.first_name rlike ? or a.last_name rlike ? limit ?, ?", search_term, search_term, search_term, offset, per_page )
  res.each do |c|
    authors = repository(:default).adapter.select("select a.first_name, a.last_name from authors a join author_classifications ac on ac.author_id = a.id where ac.classification_id = ?", c.id)
    c.authors = authors
  end
  res
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
  page = params[:page] || 1
  per_page = params[:per_page] || 10
  @classifications = Classification.all(:order => :updated_at.desc, :limit => per_page.to_i, :offset => ((page.to_i - 1) * per_page.to_i))
  haml :classifications
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
  
  authors = []
  data[:authors].each do |a|
    author = Author.first(a) || Author.new(a)
    author.save
    authors << author
  end if data[:authors]

  authors.each { |a| ar = AuthorClassification.new(:author => a, :classification => classification); ar.save }
  redirect '/classifications'
end

get '/search' do
  page = params[:page] || 1
  per_page = params[:per_page] || 30
  @search_term = params[:search_term]
  @classifications = search_for(@search_term, page, per_page)
  haml :classifications
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
