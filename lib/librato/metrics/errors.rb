
module Librato
  module Metrics

    class MetricsError < StandardError; end

    class CredentialsMissing < MetricsError; end
    class ApplicationInfoMissing < MetricsError; end
    class NoMetricsQueued < MetricsError; end

  end
end
