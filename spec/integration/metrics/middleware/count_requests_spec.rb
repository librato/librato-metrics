require 'spec_helper'

module Librato
  module Metrics
    module Middleware

      describe CountRequests do
        before(:all) { prep_integration_tests }

        it "counts requests" do
          CountRequests.reset
          Metrics.submit :foo => 123
          Metrics.submit :foo => 135
          expect(CountRequests.total_requests).to eq(2)
        end

        it "is resettable" do
          Metrics.submit :foo => 123
          expect(CountRequests.total_requests).to be > 0
          CountRequests.reset
          expect(CountRequests.total_requests).to eq(0)
        end

      end

    end
  end
end
