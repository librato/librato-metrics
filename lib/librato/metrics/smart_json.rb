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
        else
          def read(json)
            MultiJson.decode(json)
          end
        end

        if MultiJson.respond_to?(:dump)
          def write(data)
            MultiJson.dump(data)
          end
        else
          def write(data)
            MultiJson.encode(data)
          end
        end

      end

    end
  end
end
