$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'base64'
require 'excon'
require 'multi_json'

require 'metrics/client'
require 'metrics/collect'
require 'metrics/errors'
require 'metrics/persistence'
require 'metrics/queue'
#require 'metrics/simple'
require 'metrics/version'

module Librato

  # Metrics provides a simple wrapper for the Metrics web API.
  #
  # Some
  # of the methods Metrics provides will be documented below. Others
  # are delegated to {Client} and will be
  # documented there.
  module Metrics
    extend SingleForwardable

    TYPES = [:counter, :gauge]

    # Expose class methods of Simple via Metrics itself.
    #
    # TODO: Explain exposed interface with examples.
    def_delegators :client, :agent_identifier, :api_endpoint,
                   :api_endpoint=, :authenticate, :connection, :fetch,
                   :list, :persistence, :persistence=, :persister, :submit

    # The Librato::Metrics::Client being used by module-level
    # access.
    def self.client
      @client ||= Librato::Metrics::Client.new
    end

  end
end
