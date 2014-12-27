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

  get '/job/:id/restart' do
    @job = Job.find params[:id]
    redirect '/', 303 && return unless @job
    @job.stop if !Job.encoding.nil? && Job.encoding.id == @job.id
    @job.update state: 'queued'
    redirect '/', 303
  end

  get '/job/:id/stop' do
    @job = Job.find params[:id]
    redirect '/', 303 && return unless @job
    @job.stop if !Job.encoding.nil? && Job.encoding.id == @job.id
    @job.update state: 'canceled'
    redirect '/', 303
  end

  get '/shutdown' do
    EM.next_tick do
      EM.stop
    end
    redirect '/', 303
  end

  get '/restart' do
    Signal.trap('INT') {}

    Process.kill 'INT', 0

    EM.next_tick do
      Kernel.exec "ruby #{$PROGRAM_NAME}"
    end
    redirect '/', 303
  end
end
