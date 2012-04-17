module Librato
  module Metrics

    class Aggregator
      attr_reader :source

      def initialize(options={})
        # XXX: When isn't this needed?
        @aggregated ||= {}
        @client = options.delete(:client) || Librato::Metrics.client
        @source = options.delete(:source)
      end

      # Add a metric entry to the metric set:
      #
      # @param Hash metrics metrics to add
      def add(args)
        args.each do |k, v|
          value = v.respond_to?(:each) ? v[:value] : v

          @aggregated[k] ||= Aggregate.new
          @aggregated[k] << value
        end
      end

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

      # Remove all queued metrics
      #
      def flush
        @aggregated = {}
      end
      alias :clear :flush

      # Returns true if aggregate contains no measurements
      #
      # @return Boolean
      def empty?
        @aggregated.empty?
      end

      #### COPIED BELOW

      # The current Client instance this queue is using to authenticate
      # and connect to Librato Metrics. This will default to the primary
      # client used by the Librato::Metrics module unless it has been
      # set to something else.
      #
      # @return [Librato::Metrics::Client]
      def client
        @client ||= Librato::Metrics.client
      end

      # Persist currently queued metrics
      #
      # @return Boolean
      def submit
        raise NoMetricsQueued if self.empty?
        if persister.persist(self.client, self.queued)
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

      # The object this MetricSet will use to persist
      #
      def persister
        @persister ||= create_persister
      end

    private

      def create_persister
        type = self.client.persistence.to_s.capitalize
        Librato::Metrics::Persistence.const_get(type).new
      end

      def epoch_time
        Time.now.to_i
      end

    end
  end
end
