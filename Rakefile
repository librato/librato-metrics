require 'bundler'

# Packaging
Bundler::GemHelper.install_tasks

# Testing
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--color'
end

task :default => :spec
task :test => :spec

# Docs
require 'yard'
YARD::Rake::YardocTask.new

# IRB
desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -r ./lib/librato/metrics.rb"
end

