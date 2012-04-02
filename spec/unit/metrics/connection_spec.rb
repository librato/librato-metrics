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
        
        # TODO: verify user agent is being sent with rackup test
      end
      
      describe "network operations" do
        context "when missing client" do
          it "should raise exception" do
            lambda { subject.get 'metrics' }.should raise_error(NoClientProvided)
          end
        end
        
        context "with 400 class errors" do
          it "should not retry" do
            Middleware::CountRequests.reset
            client = Client.new
            client.api_endpoint = 'http://127.0.0.1:9296'
            client.authenticate 'foo', 'bar'
            with_rackup('status.ru') do
              #binding.pry
              lambda {
                client.connection.transport.post 'not_found'
              }.should raise_error(NotFound)
              lambda {
                client.connection.transport.post 'forbidden'
              }.should raise_error(ClientError)
            end
            Middleware::CountRequests.total_requests.should == 2
          end
        end
        
        context "with 500 class errors" do
          it "should retry" do
            Middleware::CountRequests.reset
            client = Client.new
            client.api_endpoint = 'http://127.0.0.1:9296'
            client.authenticate 'foo', 'bar'
            with_rackup('status.ru') do
              #binding.pry
              lambda {
                client.connection.transport.post 'service_unavailable'
              }.should raise_error(ServerError)
            end
            Middleware::CountRequests.total_requests.should == 4
          end
        end
      end
      
    end
    
  end
end