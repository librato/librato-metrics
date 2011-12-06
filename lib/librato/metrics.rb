$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'excon'
require 'base64'

require 'metrics/errors'
require 'metrics/persistence'
require 'metrics/queue'
require 'metrics/simple'
require 'metrics/version'

module Librato
  module Metrics
    extend SingleForwardable

    TYPES = [:counter, :gauge]

    # Expose class methods of Simple via Metrics itself.
    #
    # TODO: Explain exposed interface with examples.
    def_delegators Librato::Metrics::Simple, :api_endpoint, :api_endpoint=,
                  :authenticate, :connection, :persistence, :persistence=,
                  :persister, :submit

    def self.list(args)
    end

  end
end
