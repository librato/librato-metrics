require 'faraday'

module Librato
  module Metrics
    
    class Connection
      extend Forwardable
      
      DEFAULT_API_ENDPOINT = 'https://metrics-api.librato.com/v1/'      
      
      def_delegators :transport, :get, :post, :head, :put, :delete
            
      def initialize(options={})
        @client = options[:client]
        @api_endpoint = options[:api_endpoint]
      end
      
      # API endpoint that will be used for requests.
      #
      def api_endpoint
        @api_endpoint || DEFAULT_API_ENDPOINT
      end
      
      def transport
        @transport ||= Faraday::Connection.new(:url => api_endpoint) do |f|
          #f.use FaradayMiddleware::EncodeJson
          f.adapter Faraday.default_adapter
          f.use Faraday::Response::RaiseError
          #f.use FaradayMiddleware::ParseJson, :content_type => /\bjson$/
        end.tap do |transport|
          transport.headers[:content_type] = 'application/json'
          raise NoClientProvided unless @client
          transport.basic_auth @client.email, @client.api_key
        end
      end
      
      # User-agent used when making requests.
      #
      def user_agent
        ua_chunks = []
        agent_identifier = @client.agent_identifier
        if agent_identifier && !agent_identifier.empty?
          ua_chunks << agent_identifier
        end
        ua_chunks << "librato-metrics/#{Metrics::VERSION}"
        ua_chunks << "(#{ruby_engine}; #{RUBY_VERSION}p#{RUBY_PATCHLEVEL}; #{RUBY_PLATFORM})"
        ua_chunks << "direct-excon/#{1}"
        ua_chunks.join(' ')
      end
      
    private

      def ruby_engine
        return RUBY_ENGINE if Object.constants.include?(:RUBY_ENGINE)
        RUBY_DESCRIPTION.split[0]
      end
      
    end
    
  end
end