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
          subject.api_endpoint.should == 'https://metrics-api.librato.com/v1/'
        end
      end

      describe "#api_endpoint=" do
        it "should set api_endpoint" do
          @prior = subject.api_endpoint
          subject.api_endpoint = 'http://test.com/'
          subject.api_endpoint.should == 'http://test.com/'
          subject.api_endpoint = @prior
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

      describe "#persistence" do
        it "should default to direct" do
          subject.send(:flush_persistence)
          subject.persistence.should == :direct
        end

        it "should allow configuration of persistence method" do
          current = subject.persistence
          subject.persistence = :fake
          subject.persistence.should == :fake
          subject.persistence = current
        end
      end

      describe "#submit" do
        before(:all) do
          subject.persistence = :test
          subject.authenticate 'me@librato.com', 'foo'
        end
        after(:all) { subject.flush_authentication }

        it "should persist metrics immediately" do
          subject.persistence = :test
          subject.submit(:foo => 123).should eql true
          subject.persister.persisted.should eql({:gauges => [{:name => 'foo', :value => 123}]})
        end

        it "should tolerate muliple metrics" do
          lambda{ subject.submit :foo => 123, :bar => 456 }.should_not raise_error
          expected = {:gauges => [{:name => 'foo', :value => 123}, {:name => 'bar', :value => 456}]}
          subject.persister.persisted.should eql expected
        end
      end

      describe "#user_agent" do
        context "without an agent_identifier" do
          it "should render standard string" do
            subject.agent_identifier('')
            subject.user_agent.should start_with('librato-metrics')
          end
        end

        context "with an agent_identifier" do
          it "should render agent_identifier first" do
            subject.agent_identifier('foo', '0.5', 'bar')
            subject.user_agent.should start_with('foo/0.5')
          end
        end
      end

    end

  end
end
