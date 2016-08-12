USE_MULTI_JSON = defined?(MultiJson)

require 'json' unless USE_MULTI_JSON

module Librato
  module Metrics
    class SmartJSON
      JSON_HANDLER =
        if USE_MULTI_JSON
          MultiJson
        else
          JSON
        end
      extend SingleForwardable

      # wrap MultiJSON's implementation so we can use any version
      # prefer modern syntax if available; def once at startup
      if JSON_HANDLER.respond_to?(:load)
        def_delegator JSON_HANDLER, :load, :read
      else
        def_delegator JSON_HANDLER, :decode, :read
      end

      if JSON_HANDLER.respond_to?(:dump)
        def_delegator JSON_HANDLER, :dump, :write
      else
        def_delegator JSON_HANDLER, :encode, :write
      end

    end
  end
end
