require 'rubygems'
require 'sinatra/base'
require 'active_record'
require 'erb'

# Sinatra app for interacting with daemon
class AutoConvertApp < Sinatra::Base
  configure do
    set :threaded, false
  end

  get '/' do
    'Hello World'
  end

  get '/shutdown' do
    EM.stop
  end
end
