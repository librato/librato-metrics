require 'spec_helper'

module Librato
  module Metrics

    describe Connection do

      describe "#api_endpoint" do
        context "when not provided" do
          it "should be default" do
            subject.api_endpoint.should == 'https://metrics-api.librato.com'
          end
        end

        context "when provided" do
          it "should be respected" do
            connection = Connection.new(:api_endpoint => 'http://test.com/')
            connection.api_endpoint.should == 'http://test.com/'
          end
        end
      end

      describe "#user_agent" do
        context "without an agent_identifier" do
          it "should render standard string" do
            connection = Connection.new(:client => Client.new)
            connection.user_agent.should start_with('librato-metrics')
          end
        end

        context "with an agent_identifier" do
          it "should render agent_identifier first" do
            client = Client.new
            client.agent_identifier('foo', '0.5', 'bar')
            connection = Connection.new(:client => client)
            connection.user_agent.should start_with('foo/0.5')
          end
        end

        context "with a custom user agent set" do
          it "should use custom user agent" do
            client = Client.new
            client.custom_user_agent = 'foo agent'
            connection = Connection.new(:client => client)
            connection.user_agent.should == 'foo agent'
          end
        end

        # TODO: verify user agent is being sent with rackup test
      end

      describe "network operations" do
        context "when missing client" do
          it "should raise exception" do
            lambda { subject.get 'metrics' }.should raise_error(NoClientProvided)
          end
        end

        let(:client) do
          client = Client.new
          client.api_endpoint = 'http://127.0.0.1:9296'
          client.authenticate 'foo', 'bar'
          client
        end

        context "with 400 class errors" do
          it "should not retry" do
            Middleware::CountRequests.reset
            with_rackup('status.ru') do
              lambda {
                client.connection.transport.post 'not_found'
              }.should raise_error(NotFound)
              lambda {
                client.connection.transport.post 'forbidden'
              }.should raise_error(ClientError)
            end
            Middleware::CountRequests.total_requests.should == 2 # no retries
          end
        end

        context "with 500 class errors" do
          it "should retry" do
            Middleware::CountRequests.reset
            with_rackup('status.ru') do
              lambda {
                client.connection.transport.post 'service_unavailable'
              }.should raise_error(ServerError)
            end
            Middleware::CountRequests.total_requests.should == 4 # did retries
          end

          it "should send consistent body with retries" do
            Middleware::CountRequests.reset
            status = 0
            begin
              with_rackup('status.ru') do
                response = client.connection.transport.post do |req|
                  req.url 'retry_body'
                  req.body = '{"foo": "bar", "baz": "kaboom"}'
                end
              end
            rescue Exception => error
              status = error.response[:status].to_i
            end
            Middleware::CountRequests.total_requests.should == 4 # did retries
            status.should be(502)#, 'body should be sent for retries'
          end
        end
      end
    end

  end
end