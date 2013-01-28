module Librato
  module Metrics
    module Middleware

      class ExpectsStatus < Faraday::Response::Middleware

        def on_complete(env)
          # TODO: make exception output prettier
          case env[:status]
          when 401
            raise Unauthorized.new(env.to_s, env)
          when 403
            raise Forbidden.new(env.to_s, env)
          when 404
            raise NotFound.new(env.to_s, env)
          when 422
            raise EntityAlreadyExists.new(env.to_s, env)
          when 400..499
            raise ClientError.new(env.to_s, env)
          when 500..599
            raise ServerError.new(env.to_s, env)
          end
        end

      end

    end
  end
end