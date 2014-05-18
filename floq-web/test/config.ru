require_relative '../lib/floq/web/application'
require 'rack-livereload'
require 'better_errors'

Floq::Provider.default.use! :storage, :memory

10.times do
  Floq[:demo].push message: :foo
end

Floq::Web::Application.config.consider_all_requests_local = true
Floq::Web::Application.initialize!

use Rack::LiveReload
run Floq::Web::Application
