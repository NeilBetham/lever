#!/usr/bin/env ruby
require File.expand_path('../env', __FILE__)

# This module handles all the requests for ISO mounts from the socket
module ISO
  include EM::P::LineProtocol

  def post_init
    info 'client connected'
  end

  def send_line(data)
    debug "Sending: #{data}"
    send_data "#{data}\n"
  end

  def mkdir(dir)
    debug "mkdir: #{dir}"
    Process.open Commands.mkdir(dir)
  end

  def receive_line(line)
    command = JSON.parse(line)
    info "recevied command: #{command}"
    handle_command(command)
  end

  def handle_command(command)
    case command['action']
    when 'mount'
      iso_dir = File.basename(command['path'], File.extname(command['path'])).tr('^A-Za-z0-9', '')
      iso_full_path = File.absolute_path("#{CONFIG['ISO_MOUNTER']['WORKING_DIR']}#{File::SEPARATOR}#{iso_dir}")
      debug "mounting iso '#{command['path']}' at '#{iso_full_path}'"
      mount_iso(command['path'], iso_full_path)
        .callback { send_line JSON.generate success: true, path: iso_full_path }
        .errback { send_line JSON.generate success: false }
    when 'unmount'
      debug "unmounting '#{command['path']}'"
      unmount_iso(command['path'])
        .callback { send_line JSON.generate success: true, path: command['path'] }
        .errback { send_line JSON.generate success: false }
    else
      warn "unknown command received: '#{command}'"
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
    info 'Creating working directory'
    `mkdir #{CONFIG['ISO_MOUNTER']['WORKING_DIR']}`
    exit 'Failed to make working dir' unless $CHILD_STATUS && $CHILD_STATUS.exitstatus == 0
  end

  info 'Starting ISO mounting server'
  EventMachine.start_server "#{CONFIG['ISO_MOUNTER']['WORKING_DIR']}#{File::SEPARATOR}#{CONFIG['ISO_MOUNTER']['SOCKET_FILE']}", ISO
end
