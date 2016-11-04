require 'metrics/processor'

module Librato
  module Metrics
    class Queue
      include Processor

      attr_accessor :skip_measurement_times

      # @option opts [Integer] :autosubmit_count If set the queue will auto-submit any time it hits this number of measurements.
      # @option opts [Integer] :autosubmit_interval If set the queue will auto-submit if the given number of seconds has passed when a new metric is added.
      # @option opts [Boolean] :clear_failures Should the queue remove any queued measurements from its queue if it runs into problems with a request? (default: false)
      # @option opts [Client] :client The client object to use to connect to Metrics. (default: Librato::Metrics.client)
      # @option opts [Time|Integer] :measure_time A default measure_time to use for measurements added.
      # @option opts [String] :prefix If set will apply the given prefix to all metric names of measurements added.
      # @option opts [Boolean] :skip_measurement_times If true will not assign measurement_time to each measure as they are added.
      # @option opts [String] :source The default source to use for measurements added.
      def initialize(opts={})
        @queued = {}
        @autosubmit_count = opts[:autosubmit_count]
        @skip_measurement_times = opts[:skip_measurement_times]
        setup_common_options(opts)
      end

      # Add a metric entry to the metric set:
      #
      # @param [Hash] measurements measurements to add
      # @return [Queue] returns self
      def add(measurements)
        measurements.each do |key, value|
          multidimensional = has_tags?
          if value.respond_to?(:each)
            validate_parameters(value)
            metric = value
            metric[:name] = key.to_s
            type = metric.delete(:type) || metric.delete('type') || 'gauge'
          else
            metric = {name: key.to_s, value: value}
            type = :gauge
          end
          if @prefix
            metric[:name] = "#{@prefix}.#{metric[:name]}"
          end
          multidimensional = true if metric[:tags] || metric[:time]
          type = ("#{type}s").to_sym
          time_key = multidimensional ? :time : :measure_time
          metric[:time] = metric.delete(:measure_time) if multidimensional && metric[:measure_time]

          if metric[time_key]
            metric[time_key] = metric[time_key].to_i
            check_measure_time(metric)
          elsif !skip_measurement_times
            metric[time_key] = epoch_time
          end
          if multidimensional
            @queued[:measurements] ||= []
            @queued[:measurements] << metric
          else
            @queued[type] ||= []
            @queued[type] << metric
          end
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
      def clear
        @queued = {}
      end
      alias :flush :clear

      # Currently queued gauges
      #
      # @return Array
      def gauges
        @queued[:gauges] || []
      end

      def measurements
        @queued[:measurements] || []
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
        if mergeable.respond_to?(:queued)
          to_merge = mergeable.queued
        elsif mergeable.respond_to?(:has_key?)
          to_merge = mergeable
        else
          raise NotMergeable
        end
        Metrics::PLURAL_TYPES.each do |type|
          if to_merge[type]
            payload = reconcile(to_merge[type], to_merge[:source])
            if @queued[type]
              @queued[type] += payload
            else
              @queued[type] = payload
            end
          end
        end

        if to_merge[:measurements]
          payload = reconcile(to_merge[:measurements], to_merge[:tags])
          if @queued[:measurements]
            @queued[:measurements] += payload
          else
            @queued[:measurements] = payload
          end
        end

        submit_check
        self
      end

      # All currently queued metrics
      #
      # @return Hash
      def queued
        return {} if @queued.empty?
        globals = {}
        time = has_tags? ? :time : :measure_time
        globals[time] = @time if @time
        globals[:source] = @source if @source
        globals[:tags] = @tags if has_tags?
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
        time_keys = [:measure_time, :time]

        if time_keys.any? { |key| data[key] && data[key] < Metrics::MIN_MEASURE_TIME }
          raise InvalidMeasureTime, "Measure time for submitted metric (#{data}) is invalid."
        end
      end

      def reconcile(measurements, val)
        arr = val.is_a?(Hash) ? [@tags, :tags] : [@source, :source]
        return measurements if !val || val == arr.first
        measurements.map! do |measurement|
          unless measurement[arr.last]
            measurement[arr.last] = val
          end
          measurement
        end
        measurements
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
