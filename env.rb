require 'rubygems'
require 'bundler/setup'
require 'yaml'
require 'json'
require 'logger'

# Require all the gems
Bundler.require(:default)



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

# Modify the load path
$LOAD_PATH.unshift(File.dirname(__FILE__))

# Load all the libs
Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"].each { |f| require f }

# Load app components
Dir["#{File.dirname(__FILE__)}/app/models/concerns/*.rb"].each { |f| require f }
Dir["#{File.dirname(__FILE__)}/app/**/*.rb"].each { |f| require f }

# Load config file
CONFIG = YAML.load_file './config/config.yml'

# Setup redis connection pool
REDIS = EventMachine::Synchrony::ConnectionPool.new(size: 10) do
  Redis.new driver: :synchrony
end
