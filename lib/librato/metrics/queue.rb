require 'metrics/processor'

module Librato
  module Metrics
    class Queue
      include Processor

      attr_accessor :skip_measurement_times

      def initialize(options={})
        @queued = {}
        @autosubmit_count = options[:autosubmit_count]
        @client = options[:client] || Librato::Metrics.client
        @per_request = options[:per_request] || MEASUREMENTS_PER_REQUEST
        @skip_measurement_times = options[:skip_measurement_times]
      end

      # Add a metric entry to the metric set:
      #
      # @param Hash metrics metrics to add
      # @return Queue returns self
      def add(args)
        args.each do |key, value|
          if value.respond_to?(:each)
            metric = value
            metric[:name] = key.to_s
            type = metric.delete(:type) || metric.delete('type') || 'gauge'
          else
            metric = {:name => key.to_s, :value => value}
            type = :gauge
          end
          type = ("#{type}s").to_sym
          unless skip_measurement_times
            metric[:measure_time] ||= epoch_time
          end
          @queued[type] ||= []
          @queued[type] << metric
        end
        submit_check
        self
      end

      # Currently queued counters
      #
      # @return [Array]
      def counters
        @queued[:counters] || []
      end

      # Are any metrics currently queued?
      #
      # @return Boolean
      def empty?
        @queued.empty?
      end

      # Remove all queued metrics
      #
      def flush
        @queued = {}
      end
      alias :clear :flush
      alias :flush_queued :flush

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

      # Count of metrics currently queued
      #
      # @return Integer
      def size
        self.queued.inject(0) { |result, data| result + data.last.size }
      end
      alias :length :size
      
    private
    
      def submit_check
        if @autosubmit_count && self.length >= @autosubmit_count
          self.submit
        end
      end

    end
  end
end
