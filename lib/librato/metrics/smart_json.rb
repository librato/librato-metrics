module Librato
  module Metrics
    class SmartJSON
      extend SingleForwardable

      if defined?(::MultiJson)
        if RUBY_VERSION <= "2.3.0"
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
        else
          def self.read(json)
            # MultiJSON >= 1.3.0
            if MultiJson.respond_to?(:load)
              MultiJson.load(json)
            else
              MultiJson.decode(json)
            end
          end

          def self.write(json)
            # MultiJSON <= 1.2.0
            if MultiJson.respond_to?(:dump)
              MultiJson.dump(json)
            else
              MultiJson.encode(json)
            end
          end
        end

        def self.handler
          :multi_json
        end
      else
        require "json"

        if RUBY_VERSION <= "2.3.0"
          def_delegator JSON, :parse, :read
          def_delegator JSON, :generate, :write
        else
          def self.read(json)
            JSON.parse(json)
          end

          def self.write(json)
            JSON.generate(json)
          end
        end

        def self.handler
          :json
        end
      end
    end
  end
end
