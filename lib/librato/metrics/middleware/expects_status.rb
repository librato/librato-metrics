module Librato
  module Metrics
    module Middleware
      
      class ExpectsStatus < Faraday::Response::Middleware
        
        def on_complete(env)
          # TODO: clean up exception output
          # TODO: catch specific status codes by request
          case env[:status]
          when 404
            raise NotFound, env.to_s
          when 400..499
            raise ClientError, env.to_s
          when 500..599
            raise ServerError, env.to_s
          end
        end
        
      end
      
    end
  end
end