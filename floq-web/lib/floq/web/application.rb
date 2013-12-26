require_relative '../web'
require 'action_controller/railtie'
require 'action_view/railtie'

class Floq::Web::Application < Rails::Application
  routes.append do
    mount Floq::Web => '/'
  end

  config.root = File.expand_path '../../..', __dir__
  config.eager_load = true
  config.secret_key_base = '404'
end
