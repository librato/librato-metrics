module Librato
  module Metrics
    module Middleware

      class ExpectsStatus < Faraday::Response::Middleware

        def on_complete(env)
          sanitized = sanitize_request(env)
          case env[:status]
          when 401
            raise Unauthorized.new(sanitized.to_s, sanitized)
          when 403
            raise Forbidden.new(sanitized.to_s, sanitized)
          when 404
            raise NotFound.new(sanitized.to_s, sanitized)
          when 422
            raise EntityAlreadyExists.new(sanitized.to_s, sanitized)
          when 400..499
            raise ClientError.new(sanitized.to_s, sanitized)
          when 500..599
            raise ServerError.new(sanitized.to_s, sanitized)
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
