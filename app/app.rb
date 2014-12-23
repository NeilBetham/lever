# Sinatra app for interacting with daemon
class LeverApp < Sinatra::Base
  register Sinatra::AssetPipeline

  configure do
    set :public_folder, 'public'
    set :threaded, false
  end

  get '/' do
    @jobs = Job.all
    haml :index
  end

  get '/job/:id' do
    @job = Job.find params[:id]
    haml :job
  end

  get '/shutdown' do
    EM.stop
  end
end
