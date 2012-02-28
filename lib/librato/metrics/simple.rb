module Librato
  module Metrics

    # Class-level methods for quick one-off submission of metrics.
    #
    # @example Send a quick metric
    #   Librato::Metrics::Simple.authenticate 'fred@foo.com', 'myapikey'
    #   Librato::Metrics::Simple.save :total_vists => {:type => counter, :value => 2311}
    #
    # For more than quick one-off use, take a look at {Queue}. For
    # convenience, most of Simple's methods can be accessed directly from
    # the {Metrics} module.
    #
    class Simple

      class << self
        # class instance vars
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

        def connection
          # TODO: upate when excon connection recovery is improved.
          # @connection ||= Excon.new(self.api_endpoint, :headers => common_headers)
          Excon.new(self.api_endpoint, :headers => common_headers)
        end

        # Purge current credentials and connection
        #
        def flush_authentication
          self.email = nil
          self.api_key = nil
          @connection = nil
        end

        # Persistence type to use when saving metrics.
        # Default is :direct.
        #
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
          @queue ||= Queue.new(:skip_measurement_times => true)
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
          encoded = Base64.encode64("#{email}:#{api_key}").gsub("\n", ' ')
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
end
