
# Manages direct persistence with the Librato Metrics web API

module Librato
  module Metrics
    module Persistence
      class Direct

        # Persist the queued metrics directly to the
        # Metrics web API.
        #
        def persist(client, queued, options={})
          per_request = options[:per_request]
          if per_request
            requests = chunk_queued(queued, per_request)
          else
            requests = [queued]
          end
          requests.each do |request|
            payload = SmartJSON.write(request)
            # expects 200
            client.connection.post('metrics', payload)
          end
        end

      private

        def chunk_queued(queued, per_request)
          return [queued] if queue_count(queued) <= per_request
          reqs = []
          queued.each do |metric_type, measurements|
            if measurements.size <= per_request
              # we can fit all of this metric type in a single
              # request, so do so
              reqs << {metric_type => measurements}
            else
              # going to have to split things up
              measurements.each_slice(per_request) do |elements|
                reqs << {metric_type => elements}
              end
            end
          end
          reqs
        end

        def queue_count(queued)
          queued.inject(0) { |result, data| result + data.last.size }
        end

      end
    end
  end
end