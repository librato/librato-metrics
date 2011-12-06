module Librato
  module Metrics

    # Class-level methods for quick one-off submission of metrics.
    #
    # @example Send a quick metric
    #   Librato::Metrics::Simple.authenticate 'fred@foo.com', 'myapikey'
    #   Librato::Metrics::Simple.save :total_vists => {:type => counter, :value => 2311}
    #
    # For more than quick one-off use, take a look at {MetricSet}. For
    # convenience, most of Simple's methods can be accessed directly from
    # the {Metrics} module.
    #
    class Simple

      class << self
        # class instance vars
        attr_accessor :email, :api_key

        # Authenticate for direct persistence
        #
        # @param [String] email
        # @param [String] api_key
        def authenticate(email, api_key)
          self.email, self.api_key = email, api_key
        end

        # Persistence type to use when saving metrics.
        # Default is :direct.
        #
        def persistence
          @persistence ||= :direct
        end

        # Set persistence type to use when saving metrics.
        #
        # @param [Symbol] persistence_type
        def persistence=(method)
          @perisistence = method
        end

        def persister
          @metric_set ? @metric_set.persister : nil
        end

        # Submit a set of metrics
        #
        def save(args)
          @metric_set ||= MetricSet.new
          @metric_set.queue args
          @metric_set.save
        end

      end

    end
  end
end