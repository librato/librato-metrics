module Librato
  module Metrics
    class Collect

      MAX_RESULTS = 100

      # Aggregates all results of paginated elements, requesting more collections as needed
      #
      # @param [Excon] connection Connection to Metrics service
      # @param [String] path API uri
      # @param [Hash] query Query options
      def self.paginated_metrics connection, path, query
        results = []
        response = connection.get(:path => path,
                                  :query => query, :expects => 200)
        parsed = JSON.parse(response.body)
        results = parsed["metrics"]
        return results if parsed["query"]["found"] <= MAX_RESULTS
        query[:offset] = MAX_RESULTS
        begin
          response = connection.get(:path => path,
                                    :query => query, :expects => 200)
          parsed = JSON.parse(response.body)
          results.push(*parsed["metrics"])
          query[:offset] += MAX_RESULTS
        end while query[:offset] < parsed["query"]["found"]
        results
      end

    end
  end
end
