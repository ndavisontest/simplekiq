
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "simplekiq/version"

Gem::Specification.new do |spec|
  spec.name          = "simplekiq"
  spec.version       = Simplekiq::VERSION
  spec.authors       = ["Fletcher Fowler"]
  spec.email         = ["fletcher@chime.com"]

  spec.summary       = %q{Make sidekiq simpler}
  spec.description   = %q{Takes care of queue management and reporting}
  spec.homepage      = "https://github.com/1debit/simplekiq"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq-datadog", "~> 0.4"
  spec.add_dependency "sidekiq", "~> 5.2"
  spec.add_dependency "activesupport", ">= 3.2"

  spec.add_development_dependency "pry", "~> 0.12"
  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
