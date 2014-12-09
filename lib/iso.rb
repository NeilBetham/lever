require 'eventmachine'
require 'json'

# Module for interfacing with ISO mounting daemon
module ISO
  class Mounter < EM::Connection
    include EM::P::LineProtocol

    attr_accessor :deferrable

    def send_line(data)
      send_data "#{data}\n"
    end

    def receive_line(line)
      command = JSON.parse(line)
      if command && command['success'] == true
        @deferrable.succeed(command)
      else
        @deferrable.fail(command)
      end
    end
  end

  # Interface for ISO mounter returns defferrables
  def mount(iso_path)
    connection = EM.connect_unix_domain "#{CONFIG['main']['working_dir']}#{File::SEPARATOR}#{CONFIG['iso_mounter']['socket_file']}", ISO::Mounter
    connection.send_line JSON.generate action: 'mount', path: iso_path
    connection.deferrable = EM::DefaultDeferrable.new
  end

  def unmount(mount_path)
    connection = EM.connect_unix_domain "#{CONFIG['main']['working_dir']}#{File::SEPARATOR}#{CONFIG['iso_mounter']['socket_file']}", ISO::Mounter
    connection.send_line JSON.generate action: 'unmount', path: mount_path
    connection.deferrable = EM::DefaultDeferrable.new
  end

  module_function :mount, :unmount
end
