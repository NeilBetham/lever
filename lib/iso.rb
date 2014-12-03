require 'eventmachine'
require 'json'


module ISO
  class Mounter < EM::Connection
    include EM::P::LineProtocol

    attr_writter :defferrable

    def received_line(line)
      command = JSON.parse(line)
      if command & command[:success] == true
        @deferrable.succeed(command)
      else
        @deferrable.fail(command)
      end
    end
  end

  # Interface for ISO mounter
  def mount(iso_path)
    deferrable = EM::DefaultDefferrable.new
    connection = EM.connect CONFIG['ISO_MOUNTER']['SOCKET_PATH'], ISO::Mounter
    coonection.set_deferrable deferrable
    connection.send_data JSON.generate action: mount, path: iso_path
    deferrable
  end

  def umount(iso_path)
    deferrable = EM::DefaultDefferrable.new
    connection = EM.connect CONFIG['ISO_MOUNTER']['SOCKET_PATH'], ISO::Mounter
    coonection.set_deferrable deferrable
    connection.send_data JSON.generate action: unmount, path: iso_path
    deferrable
  end

  module_function :mount, :umount
end
