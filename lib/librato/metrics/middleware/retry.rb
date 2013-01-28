module Librato
  module Metrics
    module Middleware

      class Retry < Faraday::Middleware

        def initialize(app, retries = 3)
          @retries = retries
          super(app)
        end

        def call(env)
          retries = @retries
          env[:retries] = retries
          begin
            @app.call(env)
          rescue Librato::Metrics::ServerError, Timeout::Error,
                 Faraday::Error::ConnectionFailed
            if retries > 0
              retries -= 1 and retry
            end
            raise
          end
        end

      end

    end
  end
end