$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'metrics/persistence'
require 'metrics/queue'
require 'metrics/simple'
require 'metrics/version'

module Librato
  module Metrics
    extend SingleForwardable

    # TODO: Explain exposed interface with examples.
    def_delegators Librato::Metrics::Simple, :authenticate, :persistence,
                   :persistence=, :persister, :submit

    TYPES = [:counter, :gauge]
  end
end
