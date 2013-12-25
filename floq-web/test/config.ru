require_relative '../lib/floq/web'
require 'bundler/setup'
require 'rack-livereload'

Floq.provider = Floq::Providers::Memory

10.times do
  Floq[:demo].push message: :foo
end

use Rack::LiveReload
run Floq::Web
