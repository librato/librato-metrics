module Librato
  module Metrics
    module Middleware

      class ExpectsStatus < Faraday::Response::Middleware

        def on_complete(env)
          # TODO: make exception output prettier
          case env[:status]
          when 401
            raise Unauthorized, env.to_s
          when 403
            raise Forbidden, env.to_s
          when 404
            raise NotFound, env.to_s
          when 422
            raise EntityAlreadyExists, env.to_s
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