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
require 'metrics/collect'

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
    # @example Get data points for the last hour
    #   data = Librato::Metrics.fetch :start_time => Time.now-3600
    #
    # @example Get 15 min data points from two hours to an hour ago
    #   data = Librato::Metrics.fetch :start_time => Time.now-7200,
    #                                 :end_time => Time.now-3600,
    #                                 :resolution => 900
    #
    # A full list of query parameters can be found in the API
    # documentation: {http://dev.librato.com/v1/get/gauges/:name}
    #
    # @param [Symbol|String] metric Metric name
    # @param [Hash] options Query options
    def self.fetch(metric, options={})
      # TODO: look up type when not specified.
      type = options.delete(:type) || 'gauge'
      query = options.dup
      if query[:start_time].respond_to?(:year)
        query[:start_time] = query[:start_time].to_i
      end
      if query[:end_time].respond_to?(:year)
        query[:end_time] = query[:end_time].to_i
      end
      unless query.empty?
        query[:resolution] ||= 1
      end
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
      offset = 0
      path = "v1/metrics.json"
      Collect.paginated_metrics connection, path, query
    end

  end
end
