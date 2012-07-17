require 'metrics/processor'

module Librato
  module Metrics
    class Queue
      include Processor

      attr_accessor :skip_measurement_times

      def initialize(options={})
        @queued = {}
        @autosubmit_count = options[:autosubmit_count]
        @skip_measurement_times = options[:skip_measurement_times]
        setup_common_options(options)
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
          if metric[:measure_time]
            check_measure_time(metric)
          elsif !skip_measurement_times
            metric[:measure_time] = epoch_time
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
      
      # Combines queueable measures from the given object
      # into this queue. 
      #
      # @example Merging queues for more performant submission
      #   queue1.merge!(queue2)
      #   queue1.submit  # submits combined contents
      #
      # @return self
      def merge!(mergeable)
        raise NotMergeable unless mergeable.respond_to?(:queued)
        other_queued = mergeable.queued
        if other_queued[:gauges]
          @queued[:gauges] += other_queued[:gauges]
        end
        self
      end

      # All currently queued metrics
      #
      # @return Hash
      def queued
        return {} if @queued.empty?
        globals = {}
        globals[:source] = @source if @source
        @queued.merge(globals)
      end

      # Count of metrics currently queued
      #
      # @return Integer
      def size
        self.queued.inject(0) { |result, data| result + data.last.size }
      end
      alias :length :size
      
    private
    
      def check_measure_time(data)
        if data[:measure_time].to_i < Metrics::MIN_MEASURE_TIME
          raise InvalidMeasureTime, "Measure time for submitted metric (#{data}) is invalid."
        end
      end
    
      def submit_check
        autosubmit_check # in Processor
        if @autosubmit_count && self.length >= @autosubmit_count
          self.submit
        end
      end

    end
  end
end
