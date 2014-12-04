require 'eventmachine'
require 'json'


module ISO
  class Mounter < EM::Connection
    include EM::P::LineProtocol

    attr_accessor :deferrable

    def send_line(data)
      send_data "#{data}\n"
    end

    def receive_line(line)
      p "Got line '#{line}'"
      command = JSON.parse(line)
      if command && command['success'] == true
        p 'Got success back'
        @deferrable.succeed(command)
      else
        p 'Got fail back'
        @deferrable.fail(command)
      end
    end
  end

  # Interface for ISO mounter returns defferrables
  def mount(iso_path)
    connection = EM.connect_unix_domain CONFIG['ISO_MOUNTER']['SOCKET_PATH'], ISO::Mounter
    connection.send_line JSON.generate action: 'mount', path: iso_path
    connection.deferrable = EM::DefaultDeferrable.new
  end

  def umount(mount_path)
    connection = EM.connect_unix_domain CONFIG['ISO_MOUNTER']['SOCKET_PATH'], ISO::Mounter
    connection.send_line JSON.generate action: 'unmount', path: mount_path
    connection.deferrable = EM::DefaultDeferrable.new
  end

  module_function :mount, :umount
end
