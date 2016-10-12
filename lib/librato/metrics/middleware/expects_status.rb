module Librato
  module Metrics
    module Middleware

      class ExpectsStatus < Faraday::Response::Middleware

        def on_complete(env)
          # TODO: make exception output prettier
          case env[:status]
          when 401
            raise Unauthorized, response_values(env)
          when 403
            raise Forbidden, response_values(env)
          when 404
            raise NotFound, response_values(env)
          when 422
            raise EntityAlreadyExists, response_values(env)
          when 400..599
            raise ClientError, response_values(env)
          end
        end

        def response_values(env)
          {
            status: env.status,
            headers: env.response_headers,
            body: env.body
          }
        end
      end
    end
  end
end
