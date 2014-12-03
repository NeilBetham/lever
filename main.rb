#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'eventmachine'
require 'thin'
require 'yaml'
require 'active_record'
require 'lib/app'
require 'lib/db'

# Load config file
CONFIG = YAML.load_file './config.yml'

def init
  # Start the app
  run app: AutoConvertApp.new
end

def run(opts)
  EM.run do
    server  = opts[:server] || 'thin'
    host    = opts[:host]   || '0.0.0.0'
    port    = opts[:port]   || '4567'
    web_app = opts[:app]

    # Mount the app at /
    dispatch = Rack::Builder.app do
      map '/' do
        run web_app
      end
    end

    #Fail out if we are not running something evented
    unless ['thin', 'hatetepe', 'goliath'].include? server
      raise "Need an EM webserver, but #{server} isn't"
    end

    # Start the HTTP interface
    Rack::Server.start({
      app:    dispatch,
      server: server,
      Host:   host,
      Port:   port
    })
  end
end


init()
