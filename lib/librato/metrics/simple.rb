# this class contains logic used when the module is called in short-form operations.

module Librato
  module Metrics
    class Simple

      class << self
        # class instance vars
        attr_accessor :email, :api_key

        def authenticate(email, api_key)
          self.email, self.api_key = email, api_key
        end

      end

    end
  end
end