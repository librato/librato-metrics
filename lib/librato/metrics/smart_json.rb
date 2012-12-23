require 'multi_json'

module Librato
  module Metrics
    class SmartJSON
      JSON_HANDLER = MultiJson
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
