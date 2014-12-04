#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'eventmachine'
require 'yaml'
require 'json'
require 'lib/process'
require 'lib/commands'

# Load config file
CONFIG = YAML.load_file './config.yml'

# This module handles all the requests for ISO mounts from the socket
module ISO
  include EM::P::LineProtocol

  def post_init
    puts 'Received a new connection'
  end

  def send_line(data)
    send_data "#{data}\n"
  end

  def mkdir(dir)
    Process.open Commands.mkdir(dir)
  end

  def receive_line(line)
    command = JSON.parse(line)

    puts command

    case command['action']
    when 'mount'
      iso_dir = File.basename(command['path'],File.extname(command['path'])).tr('^A-Za-z0-9', '')
      iso_full_path = File.absolute_path("#{CONFIG['ISO_MOUNTER']['WORKING_DIR']}#{File::SEPARATOR}#{iso_dir}")
      mount_iso(command['path'], iso_full_path)
      .callback { send_line JSON.generate success: true, path: iso_full_path }
      .errback { send_line JSON.generate success: false }
    when 'unmount'
      unmount_iso(command['path'])
      .callback { send_line JSON.generate success: true, path: command['path'] }
      .errback { send_line JSON.generate success: false }
    else
      send_line JSON.generate success: false, error: 'Unkown command received'
    end
  end

  def mount_iso(target_iso, dest_dir)
    if !File.exist? dest_dir
      deferrable = EM::DefaultDeferrable.new
      mkdir(dest_dir).callback { Process.open(Commands.mount(target_iso, dest_dir)).callback { |resp| deferrable.succeed resp } }
      deferrable
    else
      Process.open Commands.mount(target_iso, dest_dir)
    end
  end

  def unmount_iso(dest_dir)
    if File.dirname(File.absolute_path(dest_dir)).include?(File.dirname(File.absolute_path(CONFIG['ISO_MOUNTER']['WORKING_DIR'])))
      Process.open Commands.unmount(dest_dir)
    else
      EM::DefaultDeferrable.new.fail
    end
  end

  def cleanup
    `rm #{CONFIG['ISO_MOUNTER']['WORKING_DIR']}#{File::SEPARATOR}#{CONFIG['ISO_MOUNTER']['SOCKET_FILE']}`
  end

  module_function :cleanup
end

EventMachine.run do
  Signal.trap('INT')  { ISO.cleanup; EventMachine.stop }
  Signal.trap('TERM') { ISO.cleanup; EventMachine.stop }

  unless File.exist? CONFIG['ISO_MOUNTER']['WORKING_DIR']
    `mkdir #{CONFIG['ISO_MOUNTER']['WORKING_DIR']}`
    exit 'Failed to make working dir' unless $CHILD_STATUS && $CHILD_STATUS.exitstatus == 0
  end

  EventMachine.start_server "#{CONFIG['ISO_MOUNTER']['WORKING_DIR']}#{File::SEPARATOR}#{CONFIG['ISO_MOUNTER']['SOCKET_FILE']}", ISO
end
