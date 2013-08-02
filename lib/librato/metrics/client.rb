module Librato
  module Metrics

    class Client
      extend Forwardable

      def_delegator :annotator, :add, :annotate

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

      def annotator
        @annotator ||= Annotator.new(:client => self)
      end

      # API endpoint to use for queries and direct
      # persistence.
      #
      # @return [String] api_endpoint
      def api_endpoint
        @api_endpoint ||= 'https://metrics-api.librato.com'
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
        # prevent successful creation if no credentials set
        raise CredentialsMissing unless (self.email and self.api_key)
        @connection ||= Connection.new(:client => self, :api_endpoint => api_endpoint,
                                       :adapter => faraday_adapter)
      end

      # Overrride user agent for this client's connections. If you
      # are trying to specify an agent identifier for developer
      # program, see #agent_identifier.
      #
      def custom_user_agent=(agent)
        @user_agent = agent
        @connection = nil
      end

      def custom_user_agent
        @user_agent
      end

      # Completely delete metrics with the given names. Be
      # careful with this, this is instant and permanent.
      #
      # @example Delete metric 'temperature'
      #   Librato::Metrics.delete :temperature
      #
      # @example Delete metrics 'foo' and 'bar'
      #   Librato::Metrics.delete :foo, :bar
      #
      # @example Delete metrics that start with 'foo'
      #   Librato::Metrics.delete :names => 'foo*', :exclude => ['foobar']
      #
      def delete(*metric_names)
        raise(NoMetricsProvided, 'Metric name missing.') if metric_names.empty?
        if metric_names[0].respond_to?(:keys) # hash form
          params = metric_names[0]
        else
          params = { :names => metric_names.map(&:to_s) }
        end
        connection.delete do |request|
          request.url connection.build_url("metrics")
          request.body = SmartJSON.write(params)
        end
        # expects 204, middleware will raise exception otherwise.
        true
      end

      # Return current adapter this client will use.
      # Defaults to Metrics.faraday_adapter if set, otherwise
      # Faraday.default_adapter
      def faraday_adapter
        @faraday_adapter ||= default_faraday_adapter
      end

      # Set faraday adapter this client will use
      def faraday_adapter=(adapter)
        @faraday_adapter = adapter
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
      #                                 :source => 'app1'
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
        # expects 200
        url = connection.build_url("metrics/#{metric}", query)
        response = connection.get(url)
        parsed = SmartJSON.read(response.body)
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
        path = "metrics"
        Collection.paginated_metrics(connection, path, query)
      end

      # Create a new queue which uses this client.
      #
      # @return [Queue]
      def new_queue(options={})
        options[:client] = self
        Queue.new(options)
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
      # @param [Symbol] persist_method
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
        @queue ||= Queue.new(:client => self,
                             :skip_measurement_times => true,
                             :clear_failures => true)
        @queue.add args
        @queue.submit
      end

      # Update metric with the given name.
      #
      # @example Update metric 'temperature'
      #   Librato::Metrics.update :temperature, :period => 15, :attributes => { :color => 'F00' }
      #
      # @example Update metric 'humidity', creating it if it doesn't exist
      #   Librato::Metrics.update 'humidity', :type => :gauge, :period => 60, :display_name => 'Humidity'
      #
      # @example Update multiple metrics by name
      #   Librato::Metrics.update :names => ["foo", "bar"], :period => 60
      #
      # @example Update all metrics that start with 'foo'
      #   Librato::Metrics.update :names => 'foo*', :exclude => ['foobar'], :display_min => 0
      #
      def update(metric, options = {})
        if metric.respond_to?(:each)
          url = "metrics" # update multiple metrics
          options = metric
        else
          url = "metrics/#{metric}" # update single
        end
        connection.put do |request|
          request.url connection.build_url(url)
          request.body = SmartJSON.write(options)
        end
      end

    private

      def default_faraday_adapter
        if Metrics.client == self
          Faraday.default_adapter
        else
          Metrics.faraday_adapter
        end
      end

      def flush_persistence
        @persistence = nil
      end

    end

  end
end