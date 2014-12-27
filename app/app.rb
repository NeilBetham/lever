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
    EM.next_tick do
      EM.stop
    end
    'Shutting down...'
  end

  get '/restart' do
    EM.next_tick do
      Kernel.exec "ruby #{$PROGRAM_NAME}"
    end
    'Restarting...'
  end
end
