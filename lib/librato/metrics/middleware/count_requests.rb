module Librato
  module Metrics
    module Middleware

      class CountRequests < Faraday::Response::Middleware
        @total_requests = 0

        class << self
          attr_reader :total_requests

          def increment
            @total_requests += 1
          end

          def reset
            @total_requests = 0
          end
        end

        def call(env)
          self.class.increment
          @app.call(env)
        end
      end

    end
  end
end
