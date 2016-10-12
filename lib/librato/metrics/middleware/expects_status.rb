module Librato
  module Metrics
    module Middleware

      class ExpectsStatus < Faraday::Response::Middleware

        def on_complete(env)
          # TODO: make exception output prettier
          case env[:status]
          when 401
            raise Unauthorized.new("unauthorized", response_values(env))
          when 403
            raise Forbidden.new("forbidden", response_values(env))
          when 404
            raise NotFound.new("not_found", response_values(env))
          when 422
            raise EntityAlreadyExists.new("entity_already_exists", response_values(env))
          when 400..499
            raise ClientError.new("client_error", response_values(env))
          when 500..599
            raise ServerError.new("server_error", response_values(env))
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
