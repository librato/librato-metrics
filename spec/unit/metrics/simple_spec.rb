require 'spec_helper'

module Librato
  module Metrics

    describe Simple do

      describe "#authenticate" do

        context "when given two arguments" do

          it "should store them as email and api_key" do
            Simple.authenticate 'test@librato.com', 'api_key'
            Simple.email.should == 'test@librato.com'
            Simple.api_key.should == 'api_key'
          end

        end

      end

    end

  end
end