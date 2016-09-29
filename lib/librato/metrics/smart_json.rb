module Librato
  module Metrics
    class SmartJSON
      extend SingleForwardable

      if defined?(::MultiJson)
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

        def self.handler
          :multi_json
        end
      else
        require "json"

        def self.read(json)
          JSON.parse(json)
        end

        def self.write(json)
          JSON.generate(json)
        end

        def self.handler
          :json
        end
      end
    end
  end
end
