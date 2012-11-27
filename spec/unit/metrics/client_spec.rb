require 'spec_helper'

module Librato
  module Metrics

    describe Client do

      describe "#agent_identifier" do
        context "when given a single string argument" do
          it "should set agent_identifier" do
            subject.agent_identifier 'mycollector/0.1 (dev_id:foo)'
            subject.agent_identifier.should == 'mycollector/0.1 (dev_id:foo)'
          end
        end

        context "when given three arguments" do
          it "should compose an agent string" do
            subject.agent_identifier('test_app', '0.5', 'foobar')
            subject.agent_identifier.should == 'test_app/0.5 (dev_id:foobar)'
          end

          context "when given an empty string" do
            it "should set to empty" do
              subject.agent_identifier ''
              subject.agent_identifier.should == ''
            end
          end
        end

        context "when given two arguments" do
          it "should raise error" do
            lambda { subject.agent_identifier('test_app', '0.5') }.should raise_error(ArgumentError)
          end
        end
      end

      describe "#api_endpoint" do
        it "should default to metrics" do
          subject.api_endpoint.should == 'https://metrics-api.librato.com'
        end
      end

      describe "#api_endpoint=" do
        it "should set api_endpoint" do
          subject.api_endpoint = 'http://test.com/'
          subject.api_endpoint.should == 'http://test.com/'
        end

        # TODO:
        # it "should ensure trailing slash"
        # it "should ensure real URI"
      end

      describe "#authenticate" do
        context "when given two arguments" do
          it "should store them as email and api_key" do
            subject.authenticate 'test@librato.com', 'api_key'
            subject.email.should == 'test@librato.com'
            subject.api_key.should == 'api_key'
          end
        end
      end

      describe "#connection" do
        it "should raise exception without authentication" do
          subject.flush_authentication
          lambda{ subject.connection }.should raise_error(Librato::Metrics::CredentialsMissing)
        end
      end
      
      describe "#faraday_adapter" do
        it "should default to Metrics default adapter" do
          Metrics.faraday_adapter = :typhoeus
          Client.new.faraday_adapter.should == Metrics.faraday_adapter
          Metrics.faraday_adapter = nil
        end
      end
   
      describe "#faraday_adapter=" do
        it "should allow setting of faraday adapter" do
          subject.faraday_adapter = :excon
          subject.faraday_adapter.should == :excon
          subject.faraday_adapter = :patron
          subject.faraday_adapter.should == :patron
        end
      end

      describe "#new_queue" do
        it "should return a new queue with client set" do
          queue = subject.new_queue
          queue.client.should be subject
        end
      end

      describe "#persistence" do
        it "should default to direct" do
          subject.send(:flush_persistence)
          subject.persistence.should == :direct
        end

        it "should allow configuration of persistence method" do
          subject.persistence = :fake
          subject.persistence.should == :fake
        end
      end

      describe "#submit" do
        it "should persist metrics immediately" do
          subject.authenticate 'me@librato.com', 'foo'
          subject.persistence = :test
          subject.submit(:foo => 123).should eql true
          subject.persister.persisted.should == {:gauges => [{:name => 'foo', :value => 123}]}
        end

        it "should tolerate muliple metrics" do
          subject.authenticate 'me@librato.com', 'foo'
          subject.persistence = :test
          lambda{ subject.submit :foo => 123, :bar => 456 }.should_not raise_error
          expected = {:gauges => [{:name => 'foo', :value => 123}, {:name => 'bar', :value => 456}]}
          subject.persister.persisted.should equal_unordered(expected)
        end
      end

    end

  end
end
