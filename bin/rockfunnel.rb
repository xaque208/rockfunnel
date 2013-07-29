#! /usr/bin/env ruby

require 'sinatra'
require 'json'
require 'yaml'
require 'slurry'
require 'collectd2graphite'
require 'pp'

config = YAML::load(File.read('etc/rockfunnel.yaml'))

set :port, 58765
set :bind, '::0', '0.0.0.0'

# Receives a json formatted hash
post '/post-collectd' do
  request.body.rewind
  raw = JSON.parse request.body.read
  unless raw.is_a? Array
    raise "received data must be json formatted array from collectd when using
      /post-collectd"
    exit 127
  end

  collectdData = Collectd2Graphite.raw_convert(raw)

  collectdData.each do |d|
    hash = Hash.new
    hash[:hash] = Hash.new
    d.keys.each do |k|
      if k.to_s == "time"
        hash[:time] = d[k]
      else
        hash[:hash][k] = d[k]
      end
    end
    Slurry::Storage.store(hash)
    #Slurry.push_to_redis(hash[:hash], hash[:time])
  end

  204
end

# Receives a json formatted hash
post '/post-json' do
  request.body.rewind
  raw = JSON.parse request.body.read
  exit 127 unless raw.is_a? Hash
  begin
    Slurry::Storage.store(raw)
  rescue => e
    puts e.message
    puts e.backtrace.inspect
  end

  204
end

# Report stats on the cache
get '/report' do
  Slurry::Storage::Redis.report.to_json
end

# Check out whats in the cache
get '/inspect' do
  Slurry::Storage::Redis.inspect.to_json
end

# Drop everything in the cache
get '/clean' do
  Slurry::Storage::Redis.clean
end

# Write everything in the cache to graphite
get '/flush' do
  Slurry.flush
end

