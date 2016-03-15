module Librato
  module Metrics

    class Client
      extend Forwardable

      def_delegator :annotator, :add, :annotate

      attr_accessor :email, :api_key, :proxy

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
                                       :adapter => faraday_adapter, :proxy => self.proxy)
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
      #   Librato::Metrics.delete_metrics :temperature
      #
      # @example Delete metrics 'foo' and 'bar'
      #   Librato::Metrics.delete_metrics :foo, :bar
      #
      # @example Delete metrics that start with 'foo' except 'foobar'
      #   Librato::Metrics.delete_metrics :names => 'foo*', :exclude => ['foobar']
      #
      def delete_metrics(*metric_names)
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

      # Completely delete metrics with the given names. Be
      # careful with this, this is instant and permanent.
      #
      # @deprecated Use {#delete_metrics} instead
      def delete(*metric_names); delete_metrics(*metric_names); end

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
      # @deprecated Use {#get_metric} or {#get_measurements} instead.
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
      # documentation: {http://dev.librato.com/v1/get/metrics/:name}
      #
      # @param [Symbol|String] metric Metric name
      # @param [Hash] options Query options
      def fetch(metric, options={})
        metric = get_metric(metric, options)
        options.empty? ? metric : metric["measurements"]
      end

      # Retrieve measurements for a given composite metric definition.
      # :start_time and :resolution are required options, :end_time is
      # optional.
      #
      # @example Get 5m moving average of 'foo'
      #   measurements = Librato::Metrics.get_composite
      #     'moving_average(mean(series("foo", "*"), {size: "5"}))',
      #     :start_time => Time.now.to_i - 60*60, :resolution => 300
      #
      # @param [String] definition Composite definition
      # @param [hash] options Query options
      def get_composite(definition, options={})
        unless options[:start_time] && options[:resolution]
          raise "You must provide a :start_time and :resolution"
        end
        query = options.dup
        query[:compose] = definition
        url = connection.build_url("metrics", query)
        response = connection.get(url)
        parsed = SmartJSON.read(response.body)
        # TODO: pagination support
        parsed
      end

      # Retrieve a specific metric by name, optionally including data points
      #
      # @example Get attributes for a metric
      #   metric = Librato::Metrics.get_metric :temperature
      #
      # @example Get a metric and its 20 most recent data points
      #   metric = Librato::Metrics.get_metric :temperature, :count => 20
      #   metric['measurements'] # => {...}
      #
      # A full list of query parameters can be found in the API
      # documentation: {http://dev.librato.com/v1/get/metrics/:name}
      #
      # @param [Symbol|String] name Metric name
      # @param [Hash] options Query options
      def get_metric(name, options = {})
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
        url = connection.build_url("metrics/#{name}", query)
        response = connection.get(url)
        parsed = SmartJSON.read(response.body)
        # TODO: pagination support
        parsed
      end

      # Retrieve data points for a specific metric
      #
      # @example Get 20 most recent data points for metric
      #   data = Librato::Metrics.get_measurements :temperature, :count => 20
      #
      # @example Get 20 most recent data points for a specific source
      #   data = Librato::Metrics.get_measurements :temperature, :count => 20,
      #                                            :source => 'app1'
      #
      # @example Get the 20 most recent 15 minute data point rollups
      #   data = Librato::Metrics.get_measurements :temperature, :count => 20,
      #                                            :resolution => 900
      #
      # @example Get data points for the last hour
      #   data = Librato::Metrics.get_measurements :start_time => Time.now-3600
      #
      # @example Get 15 min data points from two hours to an hour ago
      #   data = Librato::Metrics.get_measurements :start_time => Time.now-7200,
      #                                            :end_time => Time.now-3600,
      #                                            :resolution => 900
      #
      # A full list of query parameters can be found in the API
      # documentation: {http://dev.librato.com/v1/get/metrics/:name}
      #
      # @param [Symbol|String] metric_name Metric name
      # @param [Hash] options Query options
      def get_measurements(metric_name, options = {})
        raise ArgumentError, "you must provide at least a :start_time or :count" if options.empty?
        get_metric(metric_name, options)["measurements"]
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
      #   Librato::Metrics.metrics
      #
      # @example List metrics with 'foo' in the name
      #   Librato::Metrics.metrics :name => 'foo'
      #
      # @param [Hash] options
      def metrics(options={})
        query = {}
        query[:name] = options[:name] if options[:name]
        offset = 0
        path = "metrics"
        Collection.paginated_metrics(connection, path, query)
      end

      # List currently existing metrics
      #
      # @deprecated Use {#metrics} instead
      def list(options={}); metrics(options); end

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

      # Update a single metric with new attributes.
      #
      # @example Update metric 'temperature'
      #   Librato::Metrics.update_metric :temperature, :period => 15, :attributes => { :color => 'F00' }
      #
      # @example Update metric 'humidity', creating it if it doesn't exist
      #   Librato::Metrics.update_metric 'humidity', :type => :gauge, :period => 60, :display_name => 'Humidity'
      #
      def update_metric(metric, options = {})
        url = "metrics/#{metric}"
        connection.put do |request|
          request.url connection.build_url(url)
          request.body = SmartJSON.write(options)
        end
      end

      # Update multiple metrics.
      #
      # @example Update multiple metrics by name
      #   Librato::Metrics.update_metrics :names => ["foo", "bar"], :period => 60
      #
      # @example Update all metrics that start with 'foo' that aren't 'foobar'
      #   Librato::Metrics.update_metrics :names => 'foo*', :exclude => ['foobar'], :display_min => 0
      #
      def update_metrics(metrics)
        url = "metrics" # update multiple metrics
        connection.put do |request|
          request.url connection.build_url(url)
          request.body = SmartJSON.write(metrics)
        end
      end

      # Update one or more metrics. Note that attributes are specified in
      # their own hash for updating a single metric but are included inline
      # when updating multiple metrics.
      #
      # @deprecated Use {#update_metric} or {#update_metrics} instead
      def update(metric, options={})
        if metric.respond_to?(:each)
          update_metrics(metric)
        else
          update_metric(metric, options)
        end
      end

      # Update one or more metrics. Note that attributes are specified in
      # their own hash for updating a single metric but are included inline
      # when updating multiple metrics.
      #
      # @deprecated Use #update_metric instead
      alias update update_metric

      # List sources, optionally limited by a name. See http://dev.librato.com/v1/sources
      # and http://dev.librato.com/v1/get/sources
      #
      # @example Get sources matching "production"
      #   Librato::Metrics.sources name: "production"
      #
      # @param [Hash] filter
      def sources(filter = {})
        query = {}
        query[:name] = filter[:name] if filter.has_key?(:name)
        path = "sources"
        Collection.paginated_collection("sources", connection, path, query)
      end

      # Retrieve a single source by name. See http://dev.librato.com/v1/get/sources/:name
      #
      # @example Get the source for a particular EC2 instance from Cloudwatch
      #   Librato::Metrics.get_source "us-east-1b.i-f1bc8c9c"
      #
      # @param String name
      def get_source(name)
        url = connection.build_url("sources/#{name}")
        response = connection.get(url)
        parsed = SmartJSON.read(response.body)
      end

      # Update a source by name. See http://dev.librato.com/v1/get/sources/:name
      #
      # @example Update the source display name for a particular EC2 instance from Cloudwatch
      #   Librato::Metrics.update_source "us-east-1b.i-f1bc8c9c", display_name: "Production Web 1"
      #
      # @param String name
      # @param Hash options
      def update_source(name, options = {})
        url = "sources/#{name}"
        connection.put do |request|
          request.url connection.build_url(url)
          request.body = SmartJSON.write(options)
        end
      end

      # Create a snapshot of an instrument
      #
      # @example Take a snapshot of the instrument at https://metrics-api.librato.com/v1/instruments/42 using a
      #   duration of 3 hours and ending at now.
      #   Librato::Metrics.snapshot(subject: {instrument: {href: "https://metrics-api.librato.com/v1/instruments/42"}},
      #                             duration: 3.hours, end_time: Time.now)
      #
      # @param Hash options Params for the snapshot
      # @options options [Hash] :subject An object representing the subject of the snapshot. For now, only instruments are supported
      # @options options [Numeric] :duration Time interval over which to take the snapshot, defaults to 1 hour
      # @options options [Numeric, Time] :end_time Snapshot the time period of the duration, ending with end_time. Default is "now".
      def create_snapshot(options = {})
        url = "snapshots"
        response = connection.post do |request|
          request.url connection.build_url(url)
          request.body = SmartJSON.write(options)
        end
        parsed = SmartJSON.read(response.body)
      end

      # Retrive a snapshot, to check its progress or find its image_href
      #
      # @example Get a snapshot identified by 42
      #   Librato::Metrics.get_snapshot 42
      #
      # @param [Integer|String] id
      def get_snapshot(id)
        url = "snapshots/#{id}"
        response = connection.get(url)
        parsed = SmartJSON.read(response.body)
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
