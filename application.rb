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
    "/files/#{classification.uuid}/#{classification.file_name}"
  end
end

def get_repo(params)
  classification_id = params[:classification_id]
  classification = Classification.first(@classification_id)
  repository = Grit::Repo.new(File.join(SiteConfig.files_path, classification.uuid))
  [classification_id, repository]
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
  page = params[:page] ? params[:page] : 1
  @classifications = Classification.page(page, :order => :updated_at.desc).map do |c|
    Revision.first(c.revision_hash)
  end
  haml :classifications
end

get '/classifications/new' do
  haml :classifications_new
end

post '/classifications' do
  uuid = params[:uuid]
  debugger
  dwca = DWCA.new(uuid, params[:file], SiteConfig.files_path, SiteConfig.root_path)
  data = dwca.process_file
  
  classification = Classification.first(:uuid => uuid) || Classification.new(:uuid => uuid)
  classification.save unless classification.id
  citation = Citation.first(:citation => data[:citation]) || Citation.new(:citation => data[:citation])
  citation.save unless citation.id
  authors = []
  data[:authors].each do |a|
    author = Author.first(a) || Author.new(a)
    author.save
    authors << author
  end if data[:authors]
  revision = Revision.new(:classification => classification,
               :citation => citation,
               :revision_hash => data[:revision_hash], 
               :file_name => data[:file_name], 
               :title => data[:title],
               :description => data[:description],
               :url => data[:url])

  revision.save
  authors.each { |a| ar = AuthorRevision.new(:author => a, :revision => revision); ar.save }
  classification.revision_hash = revision.revision_hash
  classification.save
  redirect '/classifications'
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
