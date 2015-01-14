module Lever
  class LogHandler
    def initialize(log_id)
      @part_queue = EventMachine::Queue.new
      @processing = false
      @log = Log.find log_id
    end

    def push_part(part)
      @part_queue.push part
      EM.next_tick { EM.synchrony { handle_parts } } unless @processing
      @processing = true
    end

    def handle_parts
      @part_queue.pop do |part|
        @log.add_part part
        @part_queue.num_waiting > 0 ? EM.next_tick { EM.synchrony { handle_parts } } : @processing = false
      end
    end
  end
end
