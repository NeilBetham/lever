#!/usr/bin/env ruby
require File.expand_path('../env', __FILE__)

# This module handles all the requests for ISO mounts from the socket
module ISO
  include EM::P::LineProtocol

  def post_init
    debug 'client connected'
  end

  def send_line(data)
    info "Sending: #{data}"
    send_data "#{data}\n"
  end

  def mkdir(dir)
    debug "mkdir: #{dir}"
    Process.open Commands.mkdir(dir)
  end

  def rm(dir)
    debug "rm: #{dir}"
    Process.open Commands.rm(dir)
  end

  def receive_line(line)
    command = JSON.parse(line)
    info "recevied command: #{command}"
    handle_command(command)
  end

  def handle_command(command)
    case command['action']
    when 'mount'
      debug "mounting iso '#{command['path']}' at '#{iso_mount_dir(command['path'])}'"
      mount_iso(command['path'], iso_mount_dir(command['path']))
        .callback { send_line JSON.generate success: true, path: iso_mount_dir(command['path']) }
        .errback { |resp| send_line JSON.generate success: false, message: resp }
    when 'unmount'
      debug "unmounting '#{command['path']}'"
      unmount_iso(command['path'])
        .callback { send_line JSON.generate success: true, path: command['path'] }
        .errback { |resp| send_line JSON.generate success: false, message: resp }
    else
      warn "unknown command received: '#{command}'"
      send_line JSON.generate success: false, error: 'Unkown command received'
    end
  end

  def iso_mount_dir(iso)
    iso_dir = File.basename(iso, File.extname(iso)).tr('^A-Za-z0-9', '')
    File.absolute_path("#{CONFIG['main']['working_dir']}#{File::SEPARATOR}#{iso_dir}")
  end

  def mount_iso(target_iso, dest_dir)
    if File.dirname(File.absolute_path(target_iso)).include?(File.absolute_path(CONFIG['main']['scan_dir']))
      if !File.exist? dest_dir
        deferrable = EM::DefaultDeferrable.new
        mkdir(dest_dir).callback { Process.open(Commands.mount(target_iso, dest_dir)).callback { |resp| deferrable.succeed resp } }
        deferrable
      else
        Process.open Commands.mount(target_iso, dest_dir)
      end
    else
      msg = "iso #{target_iso} is not in the scan directory, not mounting"
      error msg
      deferrable = EM::DefaultDeferrable.new
      deferrable.fail msg
      deferrable
    end
  end

  def unmount_iso(dest_dir)
    deferrable = EM::DefaultDeferrable.new
    if File.dirname(File.absolute_path(dest_dir)).include?(File.absolute_path(CONFIG['main']['working_dir']))
      Process.open(Commands.unmount(dest_dir))
        .errback { |error| deferrable.fail error }
        .callback do
          Process.open(Commands.rm(dest_dir))
            .errback { |resp| deferrable.fail resp }
            .callback { |resp| deferrable.succeed resp }
        end
    else
      msg = "path #{dest_dir} is not in the working directory, refusing un-mounting"
      error msg
      deferrable.fail msg
    end
    deferrable
  end

  def cleanup
    `rm #{CONFIG['main']['working_dir']}#{File::SEPARATOR}#{CONFIG['iso_mounter']['socket_file']}`
  end

  module_function :cleanup
end

EventMachine.run do
  Signal.trap('INT')  { ISO.cleanup; EventMachine.stop }
  Signal.trap('TERM') { ISO.cleanup; EventMachine.stop }


  # Check if working dir exists
  unless File.exist? CONFIG['main']['working_dir']
    info 'Creating working directory'
    `mkdir #{CONFIG['main']['working_dir']}`
  end

  # Exit if no working dir
  unless File.exist? CONFIG['main']['working_dir']
    error 'Working direcotry does not exist and was not created'
    exit 1
  end



  info 'Starting ISO mounting daemon'
  EventMachine.start_server "#{CONFIG['main']['working_dir']}#{File::SEPARATOR}#{CONFIG['iso_mounter']['socket_file']}", ISO

  # Chmod the socket so everyone can talk to it
  EventMachine.next_tick { File.chmod(0777, "#{CONFIG['main']['working_dir']}#{File::SEPARATOR}#{CONFIG['iso_mounter']['socket_file']}")  }
end
