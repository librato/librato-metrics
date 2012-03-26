
# Manages direct persistence with the Librato Metrics web API

module Librato
  module Metrics
    module Persistence
      class Direct

        # Persist the queued metrics directly to the
        # Metrics web API.
        #
        def persist(client, queued)
          payload = MultiJson.encode(queued)
          # expects 200
          client.connection.post('metrics', payload)
        end

      end
    end
  end
end