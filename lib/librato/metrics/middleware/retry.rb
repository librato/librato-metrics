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
          request_body = env[:body]
          begin
            env[:body] = request_body # after failure is set to response body
            @app.call(env)
          rescue Librato::Metrics::ServerError, Timeout::Error,
                 Faraday::ConnectionFailed
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