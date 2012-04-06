module Librato
  module Metrics
    module Middleware

      class RequestBody < Faraday::Response::Middleware

        def call(env)
          # duplicate request body so it is preserved through request
          # in case we need it for exception output
          env[:request_body] = env[:body]
          @app.call(env)
        end

      end

    end
  end
end