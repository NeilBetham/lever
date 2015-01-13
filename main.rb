#!/usr/bin/env ruby
require File.expand_path('../env', __FILE__)

daemon = Lever::Daemon.new

daemon.run
