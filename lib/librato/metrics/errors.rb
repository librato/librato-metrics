
module Librato
  module Metrics

    class MetricsError < StandardError; end

    class CredentialsMissing < MetricsError; end
    class AgentInfoMissing < MetricsError; end
    class NoMetricsQueued < MetricsError; end
    class NoClientProvided < MetricsError; end
    
    class NetworkError < StandardError; end
    
    class ClientError < NetworkError; end
    class NotFound < ClientError; end
    
    class ServerError < NetworkError; end

  end
end
