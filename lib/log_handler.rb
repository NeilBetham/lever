module Lever
  # LogHandler's sole purpose is to sequentially handle parts of logs so index values remain consistent
  class LogHandler
    def initialize(log)
      @part_queue = EventMachine::Channel.new
      @processing = false
      @log = Log.find log.id
      @sync_defer = nil
    end

    # Add a part to be handled later
    def push_part(part)
      @part_queue.push part
      EM.next_tick { EM.synchrony { handle_parts } } unless @processing
      @processing = true
    end

    # Sequential part handler, handles 5 parts
    def handle_parts
      (0..4).each do
        part = @part_queue.pop

        if part
          @log.add_part part
        else
          @processing = false
          @sync_defer.succeed if @sync_defer
          return
        end
      end

      # Loop fell through so there are probably still parts left
      EM.next_tick { EM.synchrony { handle_parts } }
    end

    # Call when waiting for queue to empty
    def sync
      @sync_defer = EM::DefaultDeferrable.new
    end
  end
end
