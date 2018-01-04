module Librato::Utils
  LIBRATO_USER    = ENV['LIBRATO_USER']
  LIBRATO_API_KEY = ENV['LIBRATO_TOKEN']
  SPACES_URL = 'https://metrics-api.librato.com/v1/spaces'.freeze

  def safe_parse(json_string)
    JSON.parse json_string
  rescue JSON::ParserError
    {}
  end

  def client(url, options = {})
    Typhoeus::Request.new(url, userpwd: "#{LIBRATO_USER}:#{LIBRATO_API_KEY}",
                                method:  options.fetch(:method, :get),
                                body:    options.fetch(:body, {})
                          )
  end
end
