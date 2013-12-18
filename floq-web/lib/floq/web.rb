require 'floq'
require 'sinatra/base'

class Floq::Web < Sinatra::Base
  set :root, File.expand_path('../..', __dir__)

  set :queues, -> { @queues ||= Floq.queues }

  get '/' do
    erb :index
  end
end
