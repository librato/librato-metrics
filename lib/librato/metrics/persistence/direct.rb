
# Manages direct persistence with the Librato Metrics web API

module Librato
  module Metrics
    module Persistence
      class Direct

        # Persist the queued metrics directly to the
        # Metrics web API.
        #
        def persist(queued)
          payload = queued.to_json
          Simple.connection.post(:path => '/v1/metrics',
              :headers => {'Content-Type' => 'application/json'},
              :body => payload, :expects => 200)
        end

      end
    end
  end
end