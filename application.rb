require 'rubygems'
require 'sinatra'
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
  @classifications = Classification.page(page, :order => :updated_at.desc)
  haml :classifications
end

get '/classifications/new' do
  haml :classifications_new
end

post '/classifications' do
  name = params[:name]
  uuid = params[:uuid]
  agent_name = params[:agent]
  agent = Agent.first(:name => agent_name)
  agent = Agent.create!(:name => agent_name) unless agent
  classification = Classification.first(:uuid => uuid)
  classification = Classification.new(:name => name, :agent => agent, :uuid => uuid) unless classification
  path = File.join(SiteConfig.files_path, classification.uuid)
  unless FileTest.exists?(path)
    FileUtils.mkdir(path)
    Dir.chdir(path)
    `git init`
  end
  Dir.chdir(path)
  Dir.entries(Dir.pwd).each do |e|
    File.delete(e) if File.file?(e)
  end
  classification.file_name = params[:file][:filename]
  classification.file_type = params[:file][:type]
  classification.save
  file = open(File.join(path, classification.file_name), 'w')
  file.write(params[:file][:tempfile].read(65536))
  file.close
  Dir.chdir(path)
  `git add .`
  `git add -u`
  `git commit -m "#{Time.now.strftime('%Y-%m-%d at %I:%M:%S %p')}"`
  Dir.chdir(SiteConfig.root_path)
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
