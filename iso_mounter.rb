#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'eventmachine'
require 'yaml'
require 'json'

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

  def receive_line(line)
    command = JSON.parse(line)
    puts command
    send_line JSON.generate success: true, path: command['path']
  end
end

EventMachine.run do
  Signal.trap('INT')  { EventMachine.stop }
  Signal.trap('TERM') { EventMachine.stop }

  EventMachine.start_server CONFIG['ISO_MOUNTER']['SOCKET_PATH'], ISO
end
