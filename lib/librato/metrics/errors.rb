
module Librato
  module Metrics

    class MetricsError < StandardError; end

    class CredentialsMissing < MetricsError; end
    class NoMetricsProvided < MetricsError; end
    class NoClientProvided < MetricsError; end
    class InvalidMeasureTime < MetricsError; end
    class NotMergeable < MetricsError; end

    class NetworkError < StandardError
      attr_reader :response

      def initialize(msg, response = nil)
        super(msg)
        @response = response
      end
    end

    class ClientError < NetworkError; end
    class Unauthorized < ClientError; end
    class Forbidden < ClientError; end
    class NotFound < ClientError; end
    class EntityAlreadyExists < ClientError; end

    class ServerError < NetworkError; end

  end
end
