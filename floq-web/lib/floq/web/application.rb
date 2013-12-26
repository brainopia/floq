require_relative '../web'
require 'action_controller'
require 'rails/all'

class Floq::Web::Application < Rails::Application
  routes.append do
    mount Floq::Web => '/'
  end

  config.eager_load = true
  config.secret_key_base = '404'
end
