$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

# only load pry for MRI > 1.8
require 'pry' if RUBY_ENGINE == 'ruby' rescue nil
require 'popen4'
require 'rspec'
require 'rspec/mocks/standalone'
require 'set'

require 'librato/metrics'

RSpec.configure do |config|

  # purge all metrics from test account
  def delete_all_metrics
    connection = Librato::Metrics.client.connection
    Librato::Metrics.metrics.each do |metric|
      #puts "deleting #{metric['name']}..."
      # expects 204
      connection.delete("metrics/#{metric['name']}")
    end
  end

  # purge all annotations from test account
  def delete_all_annotations
    annotator = Librato::Metrics::Annotator.new
    streams = annotator.list
    if streams['annotations']
      names = streams['annotations'].map{|s| s['name']}
      names.each { |name| annotator.delete name}
    end
  end

  # set up test account credentials for integration tests
  def prep_integration_tests
    raise 'no TEST_API_USER specified in environment' unless ENV['TEST_API_USER']
    raise 'no TEST_API_KEY specified in environment' unless ENV['TEST_API_KEY']
    if ENV['TEST_API_ENDPOINT']
      Librato::Metrics.api_endpoint = ENV['TEST_API_ENDPOINT']
    end
    Librato::Metrics.authenticate ENV['TEST_API_USER'], ENV['TEST_API_KEY']
  end

  def rackup_path(*parts)
    File.expand_path(File.join(File.dirname(__FILE__), 'rackups', *parts))
  end

  # fire up a given rackup file for the enclosed tests
  def with_rackup(name)
    if RUBY_PLATFORM == 'java'
      pid, w, r, e = IO.popen4("rackup", rackup_path(name), '-p 9296')
    else
      GC.disable
      pid, w, r, e = Open4.popen4("rackup", rackup_path(name), '-p 9296')
    end
    until e.gets =~ /HTTPServer#start:/; end
    yield
  ensure
    Process.kill(9, pid)
    if RUBY_PLATFORM != 'java'
      GC.enable
      Process.wait(pid)
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
  result.each do |key, value|
    result[key] = value.to_set if value.respond_to?(:to_set)
  end
  match do |target|
    target.each do |key, value|
      target[key] = value.to_set if value.respond_to?(:to_set)
    end
    target == result
  end
end
