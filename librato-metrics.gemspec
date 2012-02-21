lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'librato/metrics/version'

Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'

  s.name              = 'librato-metrics'
  s.version           = Librato::Metrics::VERSION

  s.summary     = "Ruby wrapper for Librato's Metrics API"
  s.description = "An easy to use ruby wrapper for Librato's Metrics API"

  s.authors  = ["Matt Sanders"]
  s.email    = 'matt@librato.com'
  s.homepage = 'https://github.com/librato/librato-metrics'

  s.require_paths = %w[lib]

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[LICENSE]

  ## runtime dependencies
  s.add_dependency 'excon', '~> 0.9.5'
  s.add_dependency 'multi_json'

  ## development dependencies
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~>2.6.0'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'rdiscount' # for yard

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
end
