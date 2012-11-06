require 'spec_helper'

module Librato
  module Metrics
    module Middleware

      describe CountRequests do
        before(:all) { prep_integration_tests }

        it "should count requests" do
          CountRequests.reset
          Metrics.submit :foo => 123
          Metrics.submit :foo => 135
          CountRequests.total_requests.should == 2
        end

        it "should be resettable" do
          Metrics.submit :foo => 123
          CountRequests.total_requests.should > 0
          CountRequests.reset
          CountRequests.total_requests.should == 0
        end

      end

    end
  end
end
