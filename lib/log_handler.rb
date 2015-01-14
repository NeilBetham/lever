module Lever
  # LogHandler's sole purpose is to sequentially handle parts of logs so index values remain consistent
  class LogHandler
    def initialize(log_id)
      @part_queue = EventMachine::Queue.new
      @processing = false
      @log = Log.find log_id
      @sync_defer = nil
    end

    # Add a part to be handled later
    def push_part(part)
      @part_queue.push part
      EM.next_tick { EM.synchrony { handle_parts } } unless @processing
      @processing = true
    end

    # Sequential part handler
    def handle_parts
      @part_queue.pop do |part|
        @log.add_part part
        @part_queue.num_waiting > 0 ? EM.next_tick { EM.synchrony { handle_parts } } : @processing = false
        @sync_defer.succeed if @sync_defer && @part_queue.num_waiting == 0
      end
    end

    # Call when waiting for queue to empty
    def sync
      @sync_defer = EM::DefaultDeferrable.new
    end
  end
end
