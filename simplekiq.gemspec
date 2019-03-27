lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simplekiq/version'

Gem::Specification.new do |spec|
  spec.name          = 'simplekiq'
  spec.version       = Simplekiq::VERSION
  spec.authors       = ['Fletcher Fowler']
  spec.email         = ['fletcher@chime.com']

  spec.summary       = %q{Make sidekiq simpler}
  spec.description   = %q{Takes care of queue management and reporting}
  spec.homepage      = 'https://github.com/1debit/simplekiq'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://gemfury.com'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = Dir['{lib}/**/*', 'README*', 'LICENSE*']
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 3.2'
  spec.add_dependency 'dogstatsd-ruby', '>= 3.3'
  spec.add_dependency 'sidekiq', '~> 5.2'
  spec.add_dependency 'sidekiq-datadog', '~> 0.4'

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'pry-byebug', '3.7.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
