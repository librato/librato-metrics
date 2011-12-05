$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'metrics/metric_set'
require 'metrics/persistence'
require 'metrics/simple'
require 'metrics/version'

module Librato
  module Metrics

    TYPES = [:counter, :gauge]
  end
end
