# Sinatra app for interacting with daemon
class AutoConvertApp < Sinatra::Base
  register Sinatra::AssetPipeline

  configure do
    set :public_folder, 'public'
    set :threaded, false
  end

  get '/' do
    haml :index
  end

  get '/shutdown' do
    EM.stop
  end
end
