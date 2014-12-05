#!/usr/bin/env ruby
require File.expand_path('../env', __FILE__)

def init
  # Start the app
  run app: AutoConvertApp.new
end

def scan
  info 'starting scan'

end

def run(opts)
  EM.run do
    info 'auto_convert starting'

    Signal.trap('INT')  { EventMachine.stop }
    Signal.trap('TERM') { EventMachine.stop }

    server  = opts[:server] || 'thin'
    host    = opts[:host]   || '0.0.0.0'
    port    = opts[:port]   || '4568'
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

    EventMachine.add_periodic_timer( 60 ) { scan }
  end
end


init()
