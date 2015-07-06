#!/usr/bin/env ruby

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'sinatra/json'
require 'slim'
require 'pp'
require 'zip'

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

get '/modlist.?:format?' do
  if params[:format] != "json"
    slim :modlist
  else
    send_data={}
    if profiles["profiles"].key?(params[:name])
      gen_infos = lambda do |dirname|
        infos={}
        modfiles=Dir.new(dirname).each.drop_while{ |i| i =~ /^\.{1,2}$/}
        modfiles.each do |filename|
          name=dirname+"/"+filename
          if FileTest.directory?(name)
            infos[filename+"/"]=gen_infos.call(name)
          else
            if name !~ /\.(jar|zip)$/
              next
            end
            Zip::File.open(name) do |zipfile|
              if zipfile.find_entry('mcmod.info')
                modinfo_text=zipfile.read('mcmod.info').gsub(/(\r\n|\r|\n)/,"")
                if(modinfo_text.encoding !=Encoding::UTF_8)
                  modinfo_text.force_encoding("Shift_JIS").encode!("UTF-8")
                end
                begin
                  infos[filename]=JSON.load(modinfo_text)
                rescue => ex
                  next
                end
              else
                infos[filename]=nil
              end
            end
          end
        end
        return infos
      end
      @modinfos=[]
      @profile=profiles["profiles"][params[:name]]
      unless @profile.key?("gameDir") && FileTest.directory?("#{@profile["gameDir"]}/mods")
        send_data["error"]="This profile doesn't have mod dir: #{params[:name]}<br>#{@profile["gameDir"]}"
      end
      moddir_name=(@profile["gameDir"] || MinecraftHome)+"/mods"
      send_data=gen_infos.call(moddir_name)
    else
      send_data["error"]= "Not found such profile: #{params[:name]}"
    end
    json send_data
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
