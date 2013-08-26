#!/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

# Packaging
Bundler::GemHelper.install_tasks

# Gem signing
task 'before_build' do
  signing_key = File.expand_path("~/.gem/librato-private_key.pem")
  if signing_key
    puts "Key found: signing gem..."
    ENV['GEM_SIGNING_KEY'] = signing_key
  else
    puts "WARN: signing key not found, gem not signed"
  end
end
task :build => :before_build

# Testing
require 'rspec/core/rake_task'

desc "Run all tests"
task :spec do
  Rake::Task['spec:unit'].execute
  if ENV['TEST_API_USER'] && ENV['TEST_API_KEY']
    Rake::Task['spec:integration'].execute
  else
    puts "TEST_API_USER and TEST_API_KEY not in environment, skipping integration tests..."
  end
end

namespace :spec do
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.rspec_opts = '--color'
    t.pattern = 'spec/unit/**/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:integration) do |t|
    t.rspec_opts = '--color'
    t.pattern = 'spec/integration/**/*_spec.rb'
  end
end

task :default => :spec
task :test => :spec

# Docs
require 'yard'
YARD::Rake::YardocTask.new

# IRB
desc "Open an irb session preloaded with this library"
task :console do
  if !`which pry`.empty?
    sh "pry -r ./lib/librato/metrics.rb"
  else
    sh "irb -rubygems -r ./lib/librato/metrics.rb"
  end
end

