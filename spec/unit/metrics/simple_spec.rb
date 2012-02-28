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

      describe "#agent_identifier" do
        context "when given three arguments" do
          it "should store them as app_name, app_version, and dev_id" do
            Simple.agent_identifier 'test_app', '0.5', 'foobar'
            Simple.app_name.should == 'test_app'
            Simple.app_version.should == '0.5'
            Simple.dev_id.should == 'foobar'
          end
        end
      end

      describe "#persistence" do
        it "should default to direct" do
          Simple.send(:flush_persistence)
          Simple.persistence.should == :direct
        end

        it "should allow configuration of persistence method" do
          current = Simple.persistence
          Simple.persistence = :fake
          Simple.persistence.should == :fake
          Simple.persistence = current
        end
      end

      describe "#submit" do
        before(:all) do
          Simple.persistence = :test
          Simple.authenticate 'me@librato.com', 'foo'
        end
        after(:all) { Simple.flush_authentication }

        it "should persist metrics immediately" do
          Simple.persistence = :test
          Simple.submit(:foo => 123).should eql true
          Simple.persister.persisted.should eql({:gauges => [{:name => 'foo', :value => 123}]})
        end

        it "should tolerate muliple metrics" do
          lambda{ Simple.submit :foo => 123, :bar => 456 }.should_not raise_error
          expected = {:gauges => [{:name => 'foo', :value => 123}, {:name => 'bar', :value => 456}]}
          Simple.persister.persisted.should eql expected
        end
      end

    end

  end
end
