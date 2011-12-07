module Librato
  module Metrics
    class Queue

      def initialize
        @queued ||= {}
      end

      # Add a metric entry to the metric set:
      #
      # @param Hash metrics metrics to add
      # @return Hash queued_metrics the currently queued metrics
      def add(args)
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
        queued
      end

      # Currently queued counters
      #
      # @return Array
      def counters
        @queued[:counters] || []
      end

      # Remove all queued metrics
      #
      def flush
        @queued = {}
      end

      # The object this MetricSet will use to persist
      #
      def persister
        @persister ||= create_persister
      end

      # Currently queued gauges
      #
      # @return Array
      def gauges
        @queued[:gauges] || []
      end

      # All currently queued metrics
      #
      # @return Hash
      def queued
        @queued
      end

      # Persist currently queued metrics
      #
      # @return Boolean
      def submit
        if persister.persist(self.queued)
          flush and return true
        end
        false
      end

    private

      def create_persister
        type = Simple.persistence.capitalize
        Librato::Metrics::Persistence.const_get(type).new
      end

    end
  end
end