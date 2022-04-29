require 'faraday'
require 'metrics/middleware/count_requests'
require 'metrics/middleware/expects_status'
require 'metrics/middleware/request_body'
require 'metrics/middleware/retry'

module Librato
  module Metrics

    class Connection
      extend Forwardable

      DEFAULT_API_ENDPOINT = 'https://metrics-api.librato.com'

      def_delegators :transport, :get, :post, :head, :put, :delete,
                                 :build_url

      def initialize(options={})
        @client = options[:client]
        @api_endpoint = options[:api_endpoint]
        @adapter = options[:adapter]
        @proxy = options[:proxy]
      end

      # API endpoint that will be used for requests.
      #
      def api_endpoint
        @api_endpoint || DEFAULT_API_ENDPOINT
      end

      def transport
        raise(NoClientProvided, "No client provided.") unless @client
        @transport ||= Faraday::Connection.new(
          url: api_endpoint + "/v1/",
          request: {open_timeout: 20, timeout: 30}) do |f|

          f.use Librato::Metrics::Middleware::RequestBody
          f.use Librato::Metrics::Middleware::Retry
          f.use Librato::Metrics::Middleware::CountRequests
          f.use Librato::Metrics::Middleware::ExpectsStatus

          f.adapter @adapter || Metrics.faraday_adapter
          f.proxy @proxy if @proxy
        end.tap do |transport|
          transport.headers[:user_agent] = user_agent
          transport.headers[:content_type] = 'application/json'
          transport.request :basic_auth, @client.email, @client.api_key
        end
      end

      # User-agent used when making requests.
      #
      def user_agent
        return @client.custom_user_agent if @client.custom_user_agent
        ua_chunks = []
        agent_identifier = @client.agent_identifier
        if agent_identifier && !agent_identifier.empty?
          ua_chunks << agent_identifier
        end
        ua_chunks << "librato-metrics/#{Metrics::VERSION}"
        ua_chunks << "(#{ruby_engine}; #{RUBY_VERSION}p#{RUBY_PATCHLEVEL}; #{RUBY_PLATFORM})"
        ua_chunks << "direct-faraday/#{Faraday::VERSION}"
        # TODO: include adapter information
        #ua_chunks << "(#{transport_adapter})"
        ua_chunks.join(' ')
      end

    private

      def adapter_version
        adapter = transport_adapter
        case adapter
        when "NetHttp"
          "Net::HTTP/#{Net::HTTP::Revision}"
        when "Typhoeus"
          "typhoeus/#{Typhoeus::VERSION}"
        when "Excon"
          "excon/#{Excon::VERSION}"
        else
          adapter
        end
      end

      def ruby_engine
        return RUBY_ENGINE if Object.constants.include?(:RUBY_ENGINE)
        RUBY_DESCRIPTION.split[0]
      end

      # figure out which adapter faraday is using
      def transport_adapter
        transport.builder.handlers.each do |handler|
          if handler.name[0,16] == "Faraday::Adapter"
            return handler.name[18..-1]
          end
        end
      end

    end

  end
end
