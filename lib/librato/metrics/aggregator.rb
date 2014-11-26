require 'aggregate'
require 'metrics/processor'

module Librato
  module Metrics

    # If you are measuring something very frequently you can sample into
    # an aggregator and it will track and submit a single aggregate
    # measurement
    #
    # @example
    #   aggregator = Libato::Metrics::Aggregator.new
    #
    #   40.times do
    #     # do work...
    #     aggregator.add 'work.time' => work_time
    #   end
    #
    #   # send directly
    #   aggregator.submit
    #
    #   # or merge into a queue for submission
    #   queue.merge!(aggregator)
    #
    class Aggregator
      SOURCE_SEPARATOR = '%%' # must not be in valid source name criteria

      include Processor

      attr_reader :source

      # @option opts [Integer] :autosubmit_interval If set the aggregator will auto-submit if the given number of seconds has passed when a new metric is added.
      # @option opts [Boolean] :clear_failures Should the aggregator remove all stored data if it runs into problems with a request? (default: false)
      # @option opts [Client] :client The client object to use to connect to Metrics. (default: Librato::Metrics.client)
      # @option opts [Time|Integer] :measure_time A default measure_time to use for measurements added.
      # @option opts [String] :prefix If set will apply the given prefix to all metric names of measurements added.
      # @option opts [String] :source The default source to use for measurements added.
      def initialize(opts={})
        @aggregated = {}
        setup_common_options(opts)
      end

      # Add a metric entry to the metric set:
      #
      # @example Basic use
      #   aggregator.add 'request.time' => 30.24
      #
      # @example With a custom source
      #   aggregator.add 'request.time' => {value: 20.52, source: 'staging'}
      #
      # @param [Hash] measurements measurements to add
      # @return [Aggregator] returns self
      def add(measurements)
        measurements.each do |metric, data|
          if @prefix
            metric = "#{@prefix}.#{metric}"
          end
          if data.respond_to?(:each) # hash form
            value = data[:value]
            if data[:source]
              metric = "#{metric}#{SOURCE_SEPARATOR}#{data[:source]}"
            end
          else
            value = data
          end

          @aggregated[metric] ||= Aggregate.new
          @aggregated[metric] << value
        end
        autosubmit_check
        self
      end

      # Returns true if aggregate contains no measurements
      #
      # @return [Boolean]
      def empty?
        @aggregated.empty?
      end

      # Remove all queued metrics
      #
      def clear
        @aggregated = {}
      end
      alias :flush :clear

      # Returns currently queued data
      #
      def queued
        gauges = []

        @aggregated.each do |metric, data|
          source = nil
          metric = metric.to_s
          if metric.include?(SOURCE_SEPARATOR)
            metric, source = metric.split(SOURCE_SEPARATOR)
          end
          entry = {
            :name => metric,
            :count => data.count,
            :sum => data.sum,

            # TODO: make float/non-float consistent in the gem
            :min => data.min.to_f,
            :max => data.max.to_f
            # TODO: expose v.sum2 and include
          }
          entry[:source] = source if source
          gauges << entry
        end

        req = { :gauges => gauges }
        req[:source] = @source if @source
        req[:measure_time] = @measure_time if @measure_time

        req
      end

    end
  end
end
