#!/usr/bin/env ruby
require File.expand_path('../env', __FILE__)

def init
  # Start the app
  run app: LeverApp.new
end

def scan
  info 'starting scan'
  Lever.scan_dir
end

def run_queued_encode
  info 'checking for jobs to encode'
  to_encode = Job.next_job_to_encode
  to_encode.encode unless to_encode.nil?
end

def check_for_stopped_encodes
  info 'Checking for stopped encodes'
  to_encode = Job.encoding
  to_encode.encode unless to_encode.nil?
end

def run(opts)
  EM.synchrony do
    info 'Lever starting'

    web_app = opts[:app]
    event_channel = EventMachine::Channel.new

    # Check for connection to redis
    unless REDIS.ping == 'PONG'
      error 'Can\'t talk to redis'
      exit 1
    end

    # Flush redis DB
    REDIS.flushdb

    # Setup websocket channel
    LeverApp.set :event_channel, event_channel

    # Handle channel messages
    event_channel.subscribe do |msg|
      web_app.settings.websockets.each do |socket|
        socket.send msg
      end
    end

    Signal.trap('INT')  { EventMachine.stop }
    Signal.trap('TERM') { EventMachine.stop }

    server  = opts[:server] || 'thin'
    host    = opts[:host]   || '0.0.0.0'
    port    = opts[:port]   || '4567'
    web_app = opts[:app]

    # Mount the app at /
    dispatch = Rack::Builder.app do
      use Rack::FiberPool

      map '/' do
        run web_app
      end
    end

    # Fail out if we are not running something evented
    unless %w(thin hatetepe goliath).include? server
      fail "Need an EM webserver, but #{server} isn't"
    end

    # Start the HTTP interface
    Rack::Server.start(
      app:    dispatch,
      server: server,
      Host:   host,
      Port:   port
    )

    check_for_stopped_encodes

    EventMachine.add_periodic_timer(eval(CONFIG['main']['scan_interval'])) { scan }
    EventMachine.add_periodic_timer(eval(CONFIG['main']['scan_interval'])) { run_queued_encode }
  end
end


init()
