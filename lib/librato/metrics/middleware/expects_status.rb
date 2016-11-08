module Librato
  module Metrics
    module Middleware

      class ExpectsStatus < Faraday::Response::Middleware

        def on_complete(env)
          case env[:status]
          when 401
            raise Unauthorized, sanitize_request(env)
          when 403
            raise Forbidden, sanitize_request(env)
          when 404
            raise NotFound, sanitize_request(env)
          when 422
            raise EntityAlreadyExists, sanitize_request(env)
          when 400..499
            raise ClientError, sanitize_request(env)
          when 500..599
            raise ServerError, sanitize_request(env)
          end
        end

        def sanitize_request(env)
          {
            status: env.status,
            url: env.url.to_s,
            user_agent: env.request_headers["User-Agent"],
            request_body: env[:request_body],
            response_headers: env.response_headers,
            response_body: env.body
          }
        end
      end
    end
  end
end
