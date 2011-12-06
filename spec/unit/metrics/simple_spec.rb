require 'spec_helper'

module Librato
  module Metrics

    describe Simple do

      describe "#api_endpoint" do
        it "should default to metrics" do
          Simple.api_endpoint.should == 'https://metrics-api.librato.com/v1/'
        end
      end

      describe "#api_endpoint=" do
        it "should set api_endpoint" do
          @prior = Simple.api_endpoint
          Simple.api_endpoint = 'http://test.com/'
          Simple.api_endpoint.should == 'http://test.com/'
          Simple.api_endpoint = @prior
        end

        # TODO:
        # it "should ensure trailing slash"
        # it "should ensure real URI"
      end

      describe "#authenticate" do
        context "when given two arguments" do
          it "should store them as email and api_key" do
            Simple.authenticate 'test@librato.com', 'api_key'
            Simple.email.should == 'test@librato.com'
            Simple.api_key.should == 'api_key'
          end
        end
      end

      describe "#connection" do
        it "should raise exception without authentication" do
          Simple.flush_authentication
          lambda{ Simple.connection }.should raise_error(Librato::Metrics::CredentialsMissing)
        end
      end

      describe "#persistence" do
        it "should default to direct" do
          Simple.persistence.should == :direct
        end

        it "should allow configuration of persistence method" do
          Simple.persistence = :test
          Simple.persistence.should == :test
        end
      end

      describe "#submit" do
        it "should persist metrics immediately" do
          Simple.persistence = :test
          Simple.submit(:foo => 123).should eql true
          Simple.persister.persisted.should eql({:gauges => [{:name => 'foo', :value => 123}]})
        end
      end

    end

  end
end