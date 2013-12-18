Gem::Specification.new do |gem|
  gem.name          = 'floq-web'
  gem.version       = '0.1'
  gem.authors       = 'brainopia'
  gem.email         = 'brainopia@evilmartians.com'
  gem.homepage      = 'https://github.com/brainopia/floq'
  gem.summary       = 'web interface for floq'
  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep %r{^spec/}
  gem.require_paths = %w(lib)

  gem.add_dependency 'floq'
  gem.add_dependency 'sinatra'
  gem.add_development_dependency 'rspec'
end
