module Librato
  module Metrics
    class Collect

      MAX_RESULTS = 100

      # Aggregates all results of paginated elements requesting more collections as needed
      #
      # @param [Excon] connection connection to Metrics service
      # @param [String] path API uri
      # @param [Hash] query Query options
      def self.paginated_metrics connection, path, query
        results = []
        response = connection.get(:path => path,
                                  :query => query, :expects => 200)
        parsed = JSON.parse(response.body)
        query.empty? ? results = parsed : results = parsed["metrics"]
        return results if query.empty? || parsed["query"]["found"] <= MAX_RESULTS
        query[:offset] = MAX_RESULTS
        while query[:offset] < parsed["query"]["found"]
          response = connection.get(:path => path,
                                    :query => query, :expects => 200)
          parsed = JSON.parse(response.body)
          results.push(*parsed["metrics"])
          query[:offset] = query[:offset] + MAX_RESULTS
        end
        results
      end

    end
  end
end
