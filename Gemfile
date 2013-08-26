source "http://rubygems.org"

platforms :jruby do
  gem 'jruby-openssl'
end

platforms :ruby_19 do
  # make available for yard under C rubies
  gem 'redcarpet'
end

gemspec

# easily generate test data
gem 'quixote'