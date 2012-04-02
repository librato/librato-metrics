# borrowed from faraday 0.8, will use official once final
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
          begin
            @app.call(env)
          rescue Librato::Metrics::ServerError, Timeout::Error
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