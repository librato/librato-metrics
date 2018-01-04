source "https://rubygems.org"

platforms :jruby do
  gem 'jruby-openssl'
end

platforms :ruby_19 do
  # make available for yard under C rubies
  gem 'redcarpet'
end

platforms :rbx do
   # rubinius stdlib
  gem 'rubysl', '~> 2.0'
  gem 'rubinius-developer_tools'
end

gemspec

gem 'rake'

gem 'typhoeus'

# docs
gem 'yard'

# debugging
gem 'pry'

# easily generate test data
gem 'quixote'

group :test do
  gem 'rspec', '~> 3.5.0'
  gem 'sinatra'
  gem 'popen4'
  gem 'multi_json'
end
