# Use for testing the interface with persistence methods

module Librato
  module Metrics
    module Persistence
      class Test

        # persist the given metrics
        def persist(client, metrics, options={})
          @persisted = metrics
          return !@return_value.nil? ? @return_value : true
        end

        # return what was persisted
        def persisted
          @persisted
        end

        # force a return value from persistence
        def return_value(value)
          @return_value = value
        end

      end
    end
  end
end