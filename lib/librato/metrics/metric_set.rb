module Librato
  module Metrics
    class MetricSet

      def initialize
        @queued ||= {}
      end

      # Currently queued counters
      #
      # @return Array
      def counters
        @queued[:counters] || []
      end

      # Currently queued gauges
      #
      # @return Array
      def gauges
        @queued[:gauges] || []
      end

      # Add a metric entry to the metric set:
      #
      # @param Hash metrics metrics to add
      # @return Hash queued_metrics the currently queued metrics
      def queue(args)
        args.each do |key, value|
          if value.respond_to?(:each)
            type = (value.delete(:type) || 'gauge')
            type = ("#{type}s").to_sym
            value[:name] = key.to_s
            @queued[type] ||= []
            @queued[type] << value
          else
            @queued[:gauges] ||= []
            @queued[:gauges] << {:name => key.to_s, :value => value}
          end
        end
      end

      # All currently queued metrics
      #
      # @return Hash
      def queued
        @queued
      end

    end
  end
end