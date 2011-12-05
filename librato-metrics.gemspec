lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'librato/metrics/version'

Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'

  s.name              = 'librato-metrics'
  s.version           = Librato::Metrics::VERSION
  s.date              = '2010-10-06'

  s.summary     = "Ruby wrapper for Librato's Metrics API"
  s.description = "An easy to use ruby wrapper for Librato's Metrics API"

  s.authors  = ["Matt Sanders"]
  s.email    = 'matt@librato.com'
  s.homepage = 'http://metrics.librato.com'

  s.require_paths = %w[lib]

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[LICENSE]

  ## runtime dependencies
  s.add_dependency 'typhoeus', '~>0.2.4'

  ## development dependencies
  s.add_development_dependency 'rspec', '~>2.6.0'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'rdiscount' # for yard

  ## Leave this section as-is. It will be automatically generated from the
  ## contents of your Git repository via the gemspec task. DO NOT REMOVE
  ## THE MANIFEST COMMENTS, they are used as delimiters by the task.
  # = MANIFEST =
  s.files = %w[]
  # = MANIFEST =

  s.test_files = s.files.select { |path| path =~ /^spec\/*_spec\.rb/ }
end
