$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'base64'
require 'excon'
require 'json'

require 'metrics/errors'
require 'metrics/persistence'
require 'metrics/queue'
require 'metrics/simple'
require 'metrics/version'

module Librato

  # Metrics provides a simple wrapper for the Metrics web API. Some
  # of the methods Metrics provides will be documented below. Others
  # are delegated to {Librato::Metrics::Simple} and will be
  # documented there.
  module Metrics
    extend SingleForwardable

    TYPES = [:counter, :gauge]

    # Expose class methods of Simple via Metrics itself.
    #
    # TODO: Explain exposed interface with examples.
    def_delegators Librato::Metrics::Simple, :api_endpoint, :api_endpoint=,
                  :authenticate, :connection, :persistence, :persistence=,
                  :persister, :submit

    # Query metric data
    #
    # @example Get attributes for a metric
    #   attrs = Librato::Metrics.fetch :temperature
    #
    # @example Get 20 most recent data points for metric
    #   data = Librato::Metrics.fetch :temperature, :count => 20
    #
    # @example Get 20 most recent data points for a specific source
    #   data = Librato::Metrics.fetch :temperature, :count => 20,
    #                                  :source => 'app1'
    #
    # @example Get the 20 most recent 15 minute data point rollups
    #   data = Librato::Metrics.fetch :temperature, :count => 20,
    #                                 :resolution => 900
    #
    # A full list of query parameters can be found in the API
    # documentation: {http://dev.librato.com/v1/get/gauges/:name}
    #
    # @param [Symbol|String] metric Metric name
    # @param [Hash] options Query options
    def self.fetch(metric, options={})
      resolution = options.delete(:resolution) || 1
      count = options.delete(:count)
      query = {}
      if count
        query.merge!({:count => count, :resolution => resolution})
      end
      query.merge!(options)
      # TODO: look up type when not specified.
      type = options.delete(:type) || 'gauge'
      response = connection.get(:path => "v1/#{type}s/#{metric}.json",
                                :query => query, :expects => 200)
      parsed = JSON.parse(response.body)
      # TODO: pagination support
      query.empty? ? parsed : parsed["measurements"]
    end

    # List currently existing metrics
    #
    # @example List all metrics
    #   Librato::Metrics.list
    #
    # @example List metrics with 'foo' in the name
    #   Librato::Metrics.list :name => 'foo'
    #
    # @param [Hash] options
    def self.list(options={})
      query = {}
      query[:name] = options[:name] if options[:name]
      response = connection.get(:path => 'v1/metrics.json',
                                :query => query, :expects => 200)
      # TODO: pagination support
      JSON.parse(response.body)["metrics"]
    end

  end
end
