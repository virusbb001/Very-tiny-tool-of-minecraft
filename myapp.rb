require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'slim'
require 'pp'

MinecraftHome="/Users/virus/Library/Application Support/minecraft"
profiles=JSON.parse(
  File.open("#{MinecraftHome}/launcher_profiles.json").read
)

get '/' do
  @profiles=profiles
  slim :index
end

get '/show' do
  redirect to('/') unless params[:name]
  if profiles["profiles"].key?(params[:name])
    @profile=profiles["profiles"][params[:name]]
    slim :show
  else
    slim :error, locals: {error_mes: "Not found such profile: #{params[:name]}"}
  end
end
