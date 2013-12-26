require 'floq'
require 'rails'
require 'action_view'
require 'slim'

Slim::Parser.default_options[:shortcut]['@'] = {
  attr: 'role'
}

class Floq::Web < Rails::Engine
  isolate_namespace Floq

  routes.append do
    get '/' => 'queues#index'
    resources :queues, only: %w(show destroy)
  end
end
