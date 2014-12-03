#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'eventmachine'
require 'yaml'
require 'lib/iso'

CONFIG = YAML.load_file './config.yml'

EM.run do
  
end
