module Librato
  module Metrics

    class Util
      SEPARATOR = "%%"

      # Builds a Hash key from metric name and tags.
      #
      # @param metric_name [String] The unique identifying metric name of the property being tracked.
      # @param tags [Hash] A set of name=value tag pairs that describe the particular data stream.
      # @return [String] the Hash key
      def self.build_key_for(metric_name, tags)
        key_name = metric_name
        tags.sort.each do |key, value|
          k = key.to_s.downcase
          v = value.is_a?(String) ? value.downcase : value
          key_name = "#{key_name}#{SEPARATOR}#{k}=#{v}"
        end
        key_name
      end

    end

  end
end
