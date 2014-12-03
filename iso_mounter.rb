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
  def receive_line(line)
    command = JSON.parse(line)
    puts command
  end
end

EventMachine.run do
  Signal.trap('INT')  { EventMachine.stop }
  Signal.trap('TERM') { EventMachine.stop }

  EventMachine.start_server CONFIG['ISO_MOUNTER']['SOCKET_PATH'], ISO
end
