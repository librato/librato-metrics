module Librato
  module Metrics
    module Middleware

      class ExpectsStatus < Faraday::Response::Middleware

        def on_complete(env)
          # TODO: make exception output prettier
          case env[:status]
          when 401
            raise Unauthorized, "unauthorized", response_values(env)
          when 403
            raise Forbidden, "forbidden", response_values(env)
          when 404
            raise NotFound, "not_found", response_values(env)
          when 422
            raise EntityAlreadyExists, "entity_already_exists", response_values(env)
          when 400..499
            raise ClientError, "client_error", response_values(env)
          when 500..599
            raise ServerError, "server_error", response_values(env)
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
