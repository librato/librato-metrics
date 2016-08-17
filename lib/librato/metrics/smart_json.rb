module Librato
  module Metrics
    class SmartJSON
      extend SingleForwardable

      @handler =
        if defined?(::MultiJson)
          # MultiJSON >= 1.3.0
          if MultiJson.respond_to?(:load)
            def_delegator MultiJson, :load, :read
          else
            def_delegator MultiJson, :decode, :read
          end

          # MultiJSON <= 1.2.0
          if MultiJson.respond_to?(:dump)
            def_delegator MultiJson, :dump, :write
          else
            def_delegator MultiJson, :encode, :write
          end

          :multi_json
        else
          require "json/ext"

          def_delegator JSON, :parse, :read
          def_delegator JSON, :generate, :write

          :json
        end

      define_singleton_method(:handler) { @handler }
    end
  end
end
