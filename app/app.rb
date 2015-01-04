# Sinatra app for interacting with daemon
class LeverApp < Sinatra::Base
  register Sinatra::AssetPipeline
  register Sinatra::Namespace

  attr_accessor :websockets

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

    set :websockets, []
  end

  get '/' do
    haml :base
  end

  get '/ws' do
    if !request.websocket?
      status 101
    else
      request.websocket do |ws|
        ws.onopen do
          ws.send('ping')
          settings.websockets << ws
        end
        ws.onclose do
          info 'websocket closed'
          settings.websockets.delete(ws) unless settings.websockets.nil?
        end
      end
    end
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

    put '/jobs/:id/stop' do
      content_type :json

      @job = Job.find params[:id]
      status 404 && return unless @job
      @job.stop if !Job.encoding.nil? && Job.encoding.id == @job.id
      @job.update state: 'canceled'
      status 204
    end

    put '/jobs/:id/restart' do
      content_type :json

      @job = Job.find params[:id]
      status 404 && return unless @job
      @job.stop if !Job.encoding.nil? && Job.encoding.id == @job.id
      @job.update state: 'queued'
      status 204
    end
  end

  get '/shutdown' do
    EM.next_tick do
      EM.stop
    end
    status 204
  end

  get '/restart' do
    Signal.trap('INT') {}

    Process.kill 'INT', 0

    EM.next_tick do
      Kernel.exec "ruby #{$PROGRAM_NAME}"
    end
    status 204
  end

  def websockets
    @wesockets || []
  end
end
