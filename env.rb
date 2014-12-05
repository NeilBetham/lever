require 'rubygems'
require 'bundler'
require 'yaml'
require 'json'
require 'logger'

# Setup loging
module Kernel
  @@logger = Logger.new(STDOUT)

  %w(debug info warn error fatal unknown).each do |method_name|
    class_eval <<-code
    def #{method_name}(message)
      @@logger.#{method_name}(message)
    end
    code
  end
end

# Require all the gems
Bundler.require(:default)

# Modify the load path
$LOAD_PATH.unshift(File.dirname(__FILE__))

# Load all the libs
Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"].each { |f| require f }

# Load config file
CONFIG = YAML.load_file './config.yml'
