
module Librato
  module Metrics

    class MetricsError < StandardError; end

    class CredentialsMissing < MetricsError; end

  end
end
