require 'pry'

module Librato
  module Metrics
    module Middleware
      
      class ExpectsStatus < Faraday::Response::Middleware
        
        def on_complete(env)
          case env[:status]
          when 404
            raise Faraday::Error::ResourceNotFound, env.to_s
          when 400..600
            raise Faraday::Error::ClientError, env.to_s
          end
        end
        
      end
      
    end
  end
end