module Librato
  module Metrics

    class Client
      attr_accessor :email, :api_key

      # Provide agent identifier for the developer program. See:
      # http://support.metrics.librato.com/knowledgebase/articles/53548-developer-program
      #
      # @example Have the gem build your identifier string
      #   Librato::Metrics.agent_identifier 'flintstone', '0.5', 'fred'
      #
      # @example Provide your own identifier string
      #   Librato::Metrics.agent_identifier 'flintstone/0.5 (dev_id:fred)'
      #
      # @example Remove identifier string
      #   Librato::Metrics.agent_identifier ''
      def agent_identifier(*args)
        if args.length == 1
          @agent_identifier = args.first
        elsif args.length == 3
          @agent_identifier = "#{args[0]}/#{args[1]} (dev_id:#{args[2]})"
        elsif ![0,1,3].include?(args.length)
          raise ArgumentError, 'invalid arguments, see method documentation'
        end
        @agent_identifier ||= ''
      end

      # API endpoint to use for queries and direct
      # persistence.
      #
      # @return [String] api_endpoint
      def api_endpoint
        @api_endpoint ||= 'https://metrics-api.librato.com/v1/'
      end

      # Set API endpoint for use with queries and direct
      # persistence. Generally you should not need to set this
      # as it will default to the current Librato Metrics
      # endpoint.
      #
      def api_endpoint=(endpoint)
        @api_endpoint = endpoint
      end

      # Authenticate for direct persistence
      #
      # @param [String] email
      # @param [String] api_key
      def authenticate(email, api_key)
        flush_authentication
        self.email, self.api_key = email, api_key
      end

      # Current connection object
      #
      def connection
        # TODO: upate when excon connection recovery is improved.
        # @connection ||= Excon.new(self.api_endpoint, :headers => common_headers)
        Excon.defaults[:ssl_verify_peer] = false if RUBY_PLATFORM == "java"
        Excon.new(self.api_endpoint, :headers => common_headers)
      end


      # Query metric data
      #
      # @example Get attributes for a metric
      #   attrs = Librato::Metrics.fetch :temperature
      #
      # @example Get 20 most recent data points for metric
      #   data = Librato::Metrics.fetch :temperature, :count => 20
      #
      # @example Get 20 most recent data points for a specific source
      #   data = Librato::Metrics.fetch :temperature, :count => 20,
      #                                  :source => 'app1'
      #
      # @example Get the 20 most recent 15 minute data point rollups
      #   data = Librato::Metrics.fetch :temperature, :count => 20,
      #                                 :resolution => 900
      #
      # @example Get data points for the last hour
      #   data = Librato::Metrics.fetch :start_time => Time.now-3600
      #
      # @example Get 15 min data points from two hours to an hour ago
      #   data = Librato::Metrics.fetch :start_time => Time.now-7200,
      #                                 :end_time => Time.now-3600,
      #                                 :resolution => 900
      #
      # A full list of query parameters can be found in the API
      # documentation: {http://dev.librato.com/v1/get/gauges/:name}
      #
      # @param [Symbol|String] metric Metric name
      # @param [Hash] options Query options
      def fetch(metric, options={})
        query = options.dup
        if query[:start_time].respond_to?(:year)
          query[:start_time] = query[:start_time].to_i
        end
        if query[:end_time].respond_to?(:year)
          query[:end_time] = query[:end_time].to_i
        end
        unless query.empty?
          query[:resolution] ||= 1
        end
        response = connection.get(:path => "v1/metrics/#{metric}",
                                  :query => query, :expects => 200)
        parsed = MultiJson.decode(response.body)
        # TODO: pagination support
        query.empty? ? parsed : parsed["measurements"]
      end

      # Purge current credentials and connection.
      #
      def flush_authentication
        self.email = nil
        self.api_key = nil
        @connection = nil
      end

      # List currently existing metrics
      #
      # @example List all metrics
      #   Librato::Metrics.list
      #
      # @example List metrics with 'foo' in the name
      #   Librato::Metrics.list :name => 'foo'
      #
      # @param [Hash] options
      def list(options={})
        query = {}
        query[:name] = options[:name] if options[:name]
        offset = 0
        path = "v1/metrics"
        Collect.paginated_metrics connection, path, query
      end

      # Create a new queue which uses this client.
      #
      # @return [Queue]
      def new_queue
        Queue.new(:client => self)
      end

      # Persistence type to use when saving metrics.
      # Default is :direct.
      #
      # @return [Symbol]
      def persistence
        @persistence ||= :direct
      end

      # Set persistence type to use when saving metrics.
      #
      # @param [Symbol] persistence_type
      def persistence=(persist_method)
        @persistence = persist_method
      end

      # Current persister object.
      def persister
        @queue ? @queue.persister : nil
      end

      # Submit all queued metrics.
      #
      def submit(args)
        @queue ||= Queue.new(:client => self, :skip_measurement_times => true)
        @queue.add args
        @queue.submit
      end

      # User-agent used when making requests.
      #
      def user_agent
        ua_chunks = []
        if agent_identifier && !agent_identifier.empty?
          ua_chunks << agent_identifier
        end
        ua_chunks << "librato-metrics/#{Metrics::VERSION}"
        ua_chunks << "(#{ruby_engine}; #{RUBY_VERSION}p#{RUBY_PATCHLEVEL}; #{RUBY_PLATFORM})"
        ua_chunks << "direct-excon/#{Excon::VERSION}"
        ua_chunks.join(' ')
      end

    private

      def auth_header
        raise CredentialsMissing unless (self.email and self.api_key)
        encoded = Base64.encode64("#{email}:#{api_key}").gsub("\n", '')
        "Basic #{encoded}"
      end

      def common_headers
        {'Authorization' => auth_header, 'User-Agent' => user_agent}
      end

      def flush_persistence
        @persistence = nil
      end

      def ruby_engine
        return RUBY_ENGINE if Object.constants.include?(:RUBY_ENGINE)
        RUBY_DESCRIPTION.split[0]
      end

    end

  end
end