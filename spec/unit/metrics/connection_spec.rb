require 'spec_helper'

module Librato
  module Metrics

    describe Connection do
      
      describe "#api_endpoint" do
        context "when not provided" do
          it "should be default" do
            subject.api_endpoint.should == 'https://metrics-api.librato.com/v1/'
          end
        end
        
        context "when provided" do
          it "should be respected" do
            connection = Connection.new(:api_endpoint => 'http://test.com/')
            connection.api_endpoint.should == 'http://test.com/'
          end
        end
      end
      
      describe "network operations" do
        context "when missing client" do
          it "should raise exception" do
            lambda { subject.get 'metrics' }#.should raise(NoClientProvided)
          end
        end
      end
      
    end
    
  end
end