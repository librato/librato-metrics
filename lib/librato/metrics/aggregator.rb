require 'aggregate'
require 'metrics/processor'

module Librato
  module Metrics

    class Aggregator
      SOURCE_SEPARATOR = '%%' # must not be in valid source name criteria
      
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
        args.each do |metric, data|
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
      # @return Boolean
      def empty?
        @aggregated.empty?
      end

      # Remove all queued metrics
      #
      def clear
        @aggregated = {}
      end
      alias :flush :clear

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

        req
      end

    end
  end
end
