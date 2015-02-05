module Lever
  class Daemon
    def run
      EM.synchrony do
        info 'Lever starting'

        # Check for connection to redis
        unless REDIS.ping == 'PONG'
          error 'Can\'t talk to redis'
          exit 1
        end

        # Flush redis DB
        REDIS.flushdb

        setup_ws_event_channel
        catch_signals

        # Mount the app at /
        dispatch = Rack::Builder.app do
          use Rack::FiberPool

          map '/' do
            run LeverApp.new
          end
        end

        # Start the HTTP interface
        Rack::Server.start(
          app:    dispatch,
          server: 'thin',
          Host:   '0.0.0.0',
          Port:   '4567',
          signals: false
        )

        check_for_stopped_encodes

        EventMachine.add_periodic_timer(eval(CONFIG['main']['scan_interval'])) { scan }
        EventMachine.add_periodic_timer(eval(CONFIG['main']['scan_interval'])) { run_queued_encode }
      end
    end

    def scan
      EM.synchrony do
        info 'starting scan'
        Lever.scan_dir
      end
    end

    def run_queued_encode
      EM.synchrony do
        info 'checking for jobs to encode'
        to_encode = Job.next_job_to_encode
        to_encode.encode unless to_encode.nil?
      end
    end

    def check_for_stopped_encodes
      info 'Checking for stopped encodes'
      to_encode = Job.encoding
      to_encode.encode unless to_encode.nil?
    end

    def catch_signals
      Signal.trap('INT')  { EventMachine.stop }
      Signal.trap('TERM') { EventMachine.stop }
    end

    def setup_ws_event_channel
      # Setup websocket channel
      LeverApp.set :event_channel, EventMachine::Channel.new

      # Handle channel messages
      LeverApp.settings.event_channel.subscribe do |msg|
        LeverApp.settings.websockets.each do |socket|
          socket.send msg
        end
      end
    end
  end
end
