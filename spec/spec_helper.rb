$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'pry'
require 'rspec'
require 'rspec/mocks/standalone'
require 'set'

require 'librato/metrics'

RSpec.configure do |config|

  # set up test account credentials for integration tests
  def prep_integration_tests
    raise 'no TEST_API_USER specified in environment' unless ENV['TEST_API_USER']
    raise 'no TEST_API_KEY specified in environment' unless ENV['TEST_API_KEY']
    if ENV['TEST_API_ENDPOINT']
      Librato::Metrics.api_endpoint = ENV['TEST_API_ENDPOINT']
    end
    Librato::Metrics.authenticate ENV['TEST_API_USER'], ENV['TEST_API_KEY']
  end

  # purge all metrics from test account
  def delete_all_metrics
    connection = Librato::Metrics.client.connection
    Librato::Metrics.list.each do |metric|
      #puts "deleting #{metric['name']}..."
      # expects 204
      connection.delete("metrics/#{metric['name']}")
    end
  end

end

# Ex: 'foobar'.should start_with('foo') #=> true
#
RSpec::Matchers.define :start_with do |start_string|
  match do |string|
    start_length = start_string.length
    string[0..start_length-1] == start_string
  end
end

# Compares hashes of arrays by converting the arrays to 
# sets before comparision
# 
# @example
#   {:foo => [1,3,2]}.should equal_unordered({:foo => [1,2,3]})
RSpec::Matchers.define :equal_unordered do |result|
  result.each { |key, value| result[key] = value.to_set }
  match do |target|
    target.each { |key, value| target[key] = value.to_set }
    target == result
  end
end