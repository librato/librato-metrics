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
      
    end
    
  end
end