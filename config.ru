require './env'
use Rack::FiberPool

run LeverApp.new
