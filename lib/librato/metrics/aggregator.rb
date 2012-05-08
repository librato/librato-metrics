require 'aggregate'
require 'metrics/processor'

module Librato
  module Metrics

    class Aggregator
      include Processor
      
      attr_reader :source

      def initialize(options={})
        @aggregated = {}
        setup_common_options(options)
      end

      # Add a metric entry to the metric set:
      #
      # @param Hash metrics metrics to add
      # @return Aggregator returns self
      def add(args)
        args.each do |k, v|
          value = v.respond_to?(:each) ? v[:value] : v

          @aggregated[k] ||= Aggregate.new
          @aggregated[k] << value
        end
        self
      end
      
      # Returns true if aggregate contains no measurements
      #
      # @return Boolean
      def empty?
        @aggregated.empty?
      end

      # Remove all queued metrics
      #
      def flush
        @aggregated = {}
      end
      alias :clear :flush

      def queued
        gauges = []

        @aggregated.each do |k,v|
          gauges << {
            :name => k.to_s,
            :count => v.count,
            :sum => v.sum,

            # TODO: make float/non-float consistent in the gem
            :min => v.min.to_f,
            :max => v.max.to_f
            # TODO: expose v.sum2 and include
          }
        end

        req = { :gauges => gauges }
        req[:source] = @source if @source

        req
      end

    end
  end
end
