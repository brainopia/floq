require 'floq'
require 'sinatra/base'

class Floq::Web < Sinatra::Base
  set :root, File.expand_path('../..', __dir__)

  get '/' do
    erb :index
  end

  get '/queue/:name' do
    erb :queue
  end

  delete '/queue/:name' do
    queue.drop
    redirect back
  end

  helpers do
    def queue
      Floq[params[:name]] 
    end

    def queues
      Floq.queues 
    end
  end
end
