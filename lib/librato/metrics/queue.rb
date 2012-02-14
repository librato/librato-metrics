module Librato
  module Metrics
    class Queue

      attr_accessor :skip_measurement_times

      def initialize(options={})
        @queued ||= {}
        @skip_measurement_times = options.delete(:skip_measurement_times)
      end

      # Add a metric entry to the metric set:
      #
      # @param Hash metrics metrics to add
      # @return Hash queued_metrics the currently queued metrics
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
      alias :clear :flush
      alias :flush_queued :flush

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

      # Count of metrics currently queued
      #
      # @return Integer
      def size
        self.queued.inject(0) { |result, data| result + data.last.size }
      end
      alias :length :size

      # Persist currently queued metrics
      #
      # @return Boolean
      def submit
        raise NoMetricsQueued if self.queued.empty?
        if persister.persist(self.queued)
          flush and return true
        end
        false
      end

      # Capture execution time for a block and queue
      # it as the value for a metric. Times are recorded
      # in milliseconds.
      #
      # Options are the same as for {#add}.
      #
      # @example Queue API request response time
      #   queue.time :api_request_time do
      #     # API request..
      #   end
      #
      # @example Queue API request response time w/ source
      #   queue.time :api_request_time, :source => 'app1' do
      #     # API request..
      #   end
      #
      # @param [Symbol|String] name Metric name
      # @param [Hash] options Metric options
      def time(name, options={})
        start = Time.now
        yield
        duration = (Time.now - start) * 1000.0 # milliseconds
        metric = {name => options.merge({:value => duration})}
        add metric
      end
      alias :benchmark :time

    private

      def create_persister
        type = Simple.persistence.to_s.capitalize
        Librato::Metrics::Persistence.const_get(type).new
      end

      def epoch_time
        Time.now.to_i
      end

    end
  end
end
