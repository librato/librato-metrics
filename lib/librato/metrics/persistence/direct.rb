
# Manages direct persistence with the Librato Metrics web API

module Librato
  module Metrics
    module Persistence
      class Direct

        # Persist the queued metrics directly to the
        # Metrics web API.
        #
        def persist(queued)
          payload = MultiJson.encode(queued)
          Simple.connection.post('metrics',
                                 payload,
                                 {'Content-Type' => 'application/json'})
        end

      end
    end
  end
end
