module Process
  class ProcessHandler < EventMachine::Connection
    attr_accessor :recv_handler
    attr_accessor :callback

    def receive_data(data)
      return unless @recv_handler.respond_to? :call
      @recv_handler.call data
    end

    def unbind
      if get_status.exitstatus == 0
        @callback.succeed get_status
      else
        @callback.fail get_status
      end
    end
  end

  def open(cmd, recv_handler={})
    process = EM.popen(cmd, ProcessHandler)
    process.recv_handler = recv_handler
    process.callback = EM::DefaultDeferrable.new
  end

  module_function :open
end
