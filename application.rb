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
