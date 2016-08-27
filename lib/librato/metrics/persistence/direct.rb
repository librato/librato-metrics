
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
            if queued[:tags] || queued[:multidimensional]
              # request contains per-measurement tags
              queued.delete(:multidimensional) if queued[:multidimensional]
              resource = "measurements"
            else
              resource = "metrics"
            end
            payload = SmartJSON.write(request)
            # expects 200
            client.connection.post(resource, payload)
          end
        end

      private

        def chunk_queued(queued, per_request)
          return [queued] if queue_count(queued) <= per_request
          reqs = []
          # separate metric-containing values from global values
          globals = fetch_globals(queued)
          Librato::Metrics::PLURAL_TYPES.each do |metric_type|
            metrics = queued[metric_type]
            next unless metrics
            if metrics.size <= per_request
              # we can fit all of this metric type in a single request
              reqs << build_request(metric_type, metrics, globals)
            else
              # going to have to split things up
              metrics.each_slice(per_request) do |elements|
                reqs << build_request(metric_type, elements, globals)
              end
            end
          end
          reqs
        end

        def build_request(type, metrics, globals)
          {type => metrics}.merge(globals)
        end

        def fetch_globals(queued)
          queued.reject {|k, v| Librato::Metrics::PLURAL_TYPES.include?(k)}
        end

        def queue_count(queued)
          queued.reject { |key| key == :multidimensional }
            .inject(0) { |result, data| result + data.last.size }
        end

      end
    end
  end
end
