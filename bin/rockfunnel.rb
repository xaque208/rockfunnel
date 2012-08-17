#! /usr/bin/env ruby

require 'sinatra'
require 'json'
require 'yaml'
require 'rockfunnel'
require 'slurry'
require 'pp'
require 'collectd2graphite'

config = YAML::load(File.read('etc/rockfunnel.yaml'))

set :port, 58765

# Receives a json formatted hash
post '/post-collectd' do
  request.body.rewind
  raw = JSON.parse request.body.read
  exit 127 unless raw.is_a? Array

  Slurry.pipe(Collectd2Graphite.convert(raw))

end


# Receives a json formatted hash
post '/post-json' do
  request.body.rewind
  raw = JSON.parse request.body.read
  exit 127 unless raw.is_a? Hash

  Slurry.pipe(raw)

end

get '/report' do
  Slurry.report.to_json
end


get '/inspect' do
  Slurry.inspect.to_json
end

get '/graphitebound' do
  data = Slurry.inspect
  data.each do |d|
    foo = JSON.parse(d)
    foo.each do |f|
      blag = Json2Graphite.get_graphite(f, Time.now.to_i)
      puts blag
    end
  end
end

get '/cleanall' do
  Slurry.clean
end

get '/runonce' do
  Slurry.runonce(config[:graphite_server], config[:graphite_port])
end

