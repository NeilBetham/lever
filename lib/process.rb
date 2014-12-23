module Process
  class ProcessHandler < EventMachine::Connection
    attr_accessor :scope
    attr_accessor :recv_handler
    attr_accessor :callback

    def receive_data(data)
      debug "Process received #{data}"
      bound = @recv_handler.bind(@scope)
      bound.call data
    end

    def unbind
      debug "sub process exited with status #{get_status.exitstatus}"
      if get_status.exitstatus == 0
        @callback.succeed get_status
      else
        @callback.fail get_status
      end
    end
  end

  def open(cmd, scope, recv_handler={})
    cmd = "#{cmd} 2>&1"
    debug "running command #{cmd}"
    process = EM.popen(cmd, ProcessHandler)
    process.scope = scope
    process.recv_handler = recv_handler
    process.callback = EM::DefaultDeferrable.new
  end

  module_function :open
end
