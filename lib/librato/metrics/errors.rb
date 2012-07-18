
module Librato
  module Metrics

    class MetricsError < StandardError; end

    class CredentialsMissing < MetricsError; end
    class NoMetricsQueued < MetricsError; end
    class NoMetricsProvided < MetricsError; end
    class NoClientProvided < MetricsError; end
    class InvalidMeasureTime < MetricsError; end
    class NotMergeable < MetricsError; end
    
    class NetworkError < StandardError; end
    
    class ClientError < NetworkError; end
    class Unauthorized < ClientError; end
    class Forbidden < ClientError; end
    class NotFound < ClientError; end
    class EntityAlreadyExists < ClientError; end
    
    class ServerError < NetworkError; end

  end
end
