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

get '/main.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :main
end

# root page
get '/' do
  redirect "/classifications"
end

# key pages
get '/keys' do
  haml :keys
end

get '/keys/:id' do
  @key = Key.first(:id => params[:id])
  haml :keys_show
end

post '/keys' do 
  key = Key.create!(:domain => params[:domain], :salt => Key.gen_salt)
  redirect "/keys/#{key.id}"
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
  path = File.join(SiteConfig.root_path, 'public', 'files', classification.uuid)
  unless FileTest.exists?(path)
    FileUtils.mkdir(path)
    `cd #{path}`
    `git init`
  end
  FileUtils.rm(path) if classification.file_name && FileTest.exists?(File.join(path, classification.file_name))
  classification.file_name = params[:file][:filename]
  classification.file_type = params[:file][:type]
  classification.save
  file = open(File.join(path, classification.file_name), 'w')
  file.write(params[:file])
  file.close
  `git add .`
  `git add -u`
  `git commit -m "#{Time.now.strftime('%Y-%m-%d at %I:%M:%S %p')}"`
  redirect '/classifications'
end
