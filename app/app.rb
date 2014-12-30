# Sinatra app for interacting with daemon
class LeverApp < Sinatra::Base
  register Sinatra::AssetPipeline
  register Sinatra::Namespace

  Rabl.register!

  configure do
    set :public_folder, 'public'
    set :threaded, false

    sprockets.append_path HandlebarsAssets.path
    HandlebarsAssets::Config.ember = true

    Rabl.configure do |config|
      config.include_json_root = false
      config.include_child_root = false
    end
  end

  get '/' do
    @jobs = Job.all
    haml :base
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

  namespace '/api' do
    get '/jobs' do
      content_type :json

      @jobs = Job.all
      rabl :jobs, format: 'json'
    end

    get '/jobs/:id' do
      content_type :json

      @job = Job.find params[:id]
      rabl :job, format: 'json'
    end

    get '/logs/:id' do
      content_type :json

      @log = Log.find params[:id]
      rabl :log, format: 'json'
    end

    patch '/jobs/:id/stop' do
      content_type :json

      @job = Job.find params[:id]
      status 404 && body('') && return unless @job
      @job.stop if !Job.encoding.nil? && Job.encoding.id == @job.id
      @job.update state: 'canceled'
      status 204 && body('')
    end

    patch '/jobs/:id/restart' do
      content_type :json

      @job = Job.find params[:id]
      status 404 && body('') && return unless @job
      @job.stop if !Job.encoding.nil? && Job.encoding.id == @job.id
      @job.update state: 'queued'
      status 204 && body('')
    end
  end

  get '/shutdown' do
    EM.next_tick do
      EM.stop
    end
    status 204 && body('')
  end

  get '/restart' do
    Signal.trap('INT') {}

    Process.kill 'INT', 0

    EM.next_tick do
      Kernel.exec "ruby #{$PROGRAM_NAME}"
    end
    status 204 && body('')
  end
end
