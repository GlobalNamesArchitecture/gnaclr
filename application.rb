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
  # add your helpers here
end

# root page
get '/' do
  haml :root
end

# key pages
get '/keys' do
  haml :keys
end

get '/keys/:id' do
  debugger
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

post '/classifications' do
  name = params[:name]
  uuid = params[:uuid]
  agent_name = params[:agent]
  agent = Agent.first(:name => agent_name)
  agent = Agent.create!(:name => agent_name) unless agent
  classification = Classification.first(:uuid => uuid)
  classification = Classification.new(:name => name, :agent => agent, :uuid => uuid) unless classification
  classification.save
  file = open(File.join(SiteConfig.root_path, 'files', classification.uuid), 'w')
  file.write(params[:file])
  file.close
  redirect '/classifications'
end
