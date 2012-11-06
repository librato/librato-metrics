# wrap MultiJSON's implementation so we can use any version
module Librato
  module Metrics
    class SmartJSON

      class << self

        # prefer modern syntax; def once at startup
        if MultiJson.respond_to?(:load)
          def read(json)
            MultiJson.load(json)
          end

          def write(data)
            MultiJson.dump(data)
          end
        else
          def read(json)
            MultiJson.decode(json)
          end

          def write(data)
            MultiJson.encode(data)
          end
        end

      end

    end
  end
end