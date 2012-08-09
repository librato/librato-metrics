module Librato
  module Metrics
    
    module Processor
      MEASUREMENTS_PER_REQUEST = 500
      
      attr_reader :per_request, :last_submit_time
      
      # The current Client instance this queue is using to authenticate
      # and connect to Librato Metrics. This will default to the primary
      # client used by the Librato::Metrics module unless it has been
      # set to something else.
      #
      # @return [Librato::Metrics::Client]
      def client
        @client ||= Librato::Metrics.client
      end

      # The object this MetricSet will use to persist
      #
      def persister
        @persister ||= create_persister
      end

      # Persist currently queued metrics
      #
      # @return Boolean
      def submit
        raise(NoMetricsQueued, "No metrics queued.") if self.queued.empty?
        options = {:per_request => @per_request}
        if persister.persist(self.client, self.queued, options)
          @last_submit_time = Time.now
          clear and return true
        end
        false
      rescue ClientError
        # clean up if we hit exceptions if asked to
        clear if @clear_on_failure
        raise
      end
      
      # Capture execution time for a block and queue
      # it as the value for a metric. Times are recorded
      # in milliseconds.
      #
      # Options are the same as for #add.
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
        yield.tap do
          duration = (Time.now - start) * 1000.0 # milliseconds
          metric = {name => options.merge({:value => duration})}
          add metric
        end
      end
      alias :benchmark :time
      
    private

      def create_persister
        type = self.client.persistence.to_s.capitalize
        Librato::Metrics::Persistence.const_get(type).new
      end

      def epoch_time
        Time.now.to_i
      end
      
      def setup_common_options(options)
        @autosubmit_interval = options[:autosubmit_interval]
        @client = options[:client] || Librato::Metrics.client
        @per_request = options[:per_request] || MEASUREMENTS_PER_REQUEST
        @source = options[:source]
        @create_time = Time.now
        @clear_on_failure = options[:clear_failures] || false
      end
      
      def autosubmit_check
        if @autosubmit_interval
          last = @last_submit_time || @create_time
          self.submit if (Time.now - last).to_i >= @autosubmit_interval
        end
      end
      
    end
    
  end
end
