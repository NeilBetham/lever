module Lever
  # LogHandler's sole purpose is to sequentially handle parts of logs so index values remain consistent
  class LogHandler
    def initialize(log)
      @part_queue = EventMachine::Queue.new
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
      @part_queue.pop do |part|
        @log.add_part part

        if @part_queue.num_waiting == 0
          @processing = false
          @sync_defer.succeed if @sync_defer
        else
          handle_parts
        end
      end
    end

    # Call when waiting for queue to empty
    def sync
      @sync_defer = EM::DefaultDeferrable.new
    end
  end
end
