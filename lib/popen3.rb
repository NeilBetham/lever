module EventMachine
  def self.popen3(*args)
    new_stderr = $stderr.dup
    rd, wr = IO::pipe
    $stderr.reopen wr
    connection = EM.popen(*args)
    $stderr.reopen new_stderr
    EM.attach rd, Popen3StderrHandler, connection
    connection
  end

  class Popen3StderrHandler < EventMachine::Connection
    def initialize(connection)
      @connection = connection
    end

    def receive_data(data)
      @connection.receive_data(data)
    end
  end
end
