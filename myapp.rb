#!/usr/bin/env ruby

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'sinatra/json'
require 'slim'
require 'pp'

configure :production do
  enable :reloader
end

MinecraftHome="/Users/virus/Library/Application Support/minecraft"
profiles=JSON.parse(
  File.open("#{MinecraftHome}/launcher_profiles.json").read
)

get '/' do
  @profiles=profiles
  slim :index
end

get '/profile' do
  redirect to('/') unless params[:name]
  if profiles["profiles"].key?(params[:name])
    @profile=profiles["profiles"][params[:name]]
    slim :profile
  else
    slim :error, locals: {error_mes: "Not found such profile: #{params[:name]}"}
  end
end

get '/modlist' do
  if profiles["profiles"].key?(params[:name])
    @profile=profiles["profiles"][params[:name]]
    if @profile.key?("gameDir") && FileTest.directory?("#{@profile["gameDir"]}/mods")
      slim :error, locals: {error_mes: "This profile doesn't have mod dir: #{params[:name]}"}
    end
    @moddir=Dir.new("#{@profile["gameDir"]}/mods")
    @modfiles=@moddir.each.drop_while { |i| i=~/^\.{1,2}$/ }
    slim :modlist
  else
    slim :error, locals: {error_mes: "Not found such profile: #{params[:name]}"}
  end
end

get '/options' do
  if profiles["profiles"].key?(params[:name])
    @profile=profiles["profiles"][params[:name]]
    @gamedir=@profile["gameDir"] || MinecraftHome
    @optionfile= @gamedir + "/options.txt"
    @options={}
    if File.exist?(@optionfile)
      File.open(@optionfile,"r") do |file|
        file.each_line do |line|
          key,value = line.split(":")
          @options[key]=value
        end
      end
      slim :options
    else
      slim :error, locals: {error_mes: "File not found: #{@optionfile}" }
    end
  else
    slim :error, locals: {error_mes: "Not found such profile: #{params[:name]}"}
  end
end

get '/options_key.?:format?' do
  send_data={}

  if profiles["profiles"].key?(params[:name])
    @profile=profiles["profiles"][params[:name]]
    @gamedir=@profile["gameDir"] || MinecraftHome
    @optionfile= @gamedir + "/options.txt"
    @options={}
    if File.exist?(@optionfile)
      File.open(@optionfile,"r") do |file|
        file.each_line do |line|
          key,value = line.chomp.split(":")
          if key=~/key/
            keys=key.split('.')
            data=send_data
            last_data=nil
            for var in keys do
              if data[var] == nil
                data[var]={}
              end
              last_data=data
              data=data[var]
            end
            last_data[keys.last]=value
          end
        end
      end
      slim :options
    else
      send_data["error"]="File not found: #{@optionfile}"
    end
  else
    send_data["error"]= "Not found such profile: #{params[:name]}"
  end

  if params[:format] == "json"
    json send_data
  elsif send_data["error"] == nil
    slim :options_key
  else
    slim :error, locals: {error_mes: send_data["error"] }
  end
end
