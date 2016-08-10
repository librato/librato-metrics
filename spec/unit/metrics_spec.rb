require 'spec_helper'

module Librato

  describe Metrics do

   describe "#authorize" do
     context "when given two arguments" do
       it "should store them on simple" do
         Metrics.authenticate 'tester@librato.com', 'api_key'
         expect(Metrics.client.email).to eq('tester@librato.com')
         expect(Metrics.client.api_key).to eq('api_key')
       end
     end
   end

   describe "#faraday_adapter" do
     it "should return current default adapter" do
       expect(Metrics.faraday_adapter).not_to be_nil
     end
   end

   describe "#faraday_adapter=" do
     before(:all) { @current_adapter = Metrics.faraday_adapter }
     after(:all) { Metrics.faraday_adapter = @current_adapter }

     it "should allow setting of faraday adapter" do
       Metrics.faraday_adapter = :excon
       expect(Metrics.faraday_adapter).to eq(:excon)
       Metrics.faraday_adapter = :patron
       expect(Metrics.faraday_adapter).to eq(:patron)
     end
   end

   describe "#persistence" do
     it "should allow configuration of persistence method" do
       Metrics.persistence = :test
       expect(Metrics.persistence).to eq(:test)
     end
   end

   describe "#submit" do
     before(:all) do
       Librato::Metrics.persistence = :test
       Librato::Metrics.authenticate 'me@librato.com', 'foo'
     end
     after(:all) { Librato::Metrics.client.flush_authentication }

     it "should persist metrics immediately" do
       Metrics.persistence = :test
       expect(Metrics.submit(:foo => 123)).to be true
       expect(Metrics.persister.persisted).to eq({:gauges => [{:name => 'foo', :value => 123}]})
     end

     it "should tolerate multiple metrics" do
       expect { Librato::Metrics.submit :foo => 123, :bar => 456 }.not_to raise_error
       expected = {:gauges => [{:name => 'foo', :value => 123}, {:name => 'bar', :value => 456}]}
       expect(Librato::Metrics.persister.persisted).to equal_unordered(expected)
     end
   end

  end

end
