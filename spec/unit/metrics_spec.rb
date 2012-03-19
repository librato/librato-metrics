require 'spec_helper'

module Librato

  describe Metrics do

   describe "#authorize" do

     context "when given two arguments" do
       it "should store them on simple" do
         Metrics.authenticate 'tester@librato.com', 'api_key'
         Metrics.client.email.should == 'tester@librato.com'
         Metrics.client.api_key.should == 'api_key'
       end
     end

   end

   describe "#persistence" do

     it "should allow configuration of persistence method" do
       Metrics.persistence = :test
       Metrics.persistence.should == :test
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
       Metrics.submit(:foo => 123).should eql true
       Metrics.persister.persisted.should eql({:gauges => [{:name => 'foo', :value => 123}]})
     end

     it "should tolerate multiple metrics" do
       lambda{ Librato::Metrics.submit :foo => 123, :bar => 456 }.should_not raise_error
       expected = {:gauges => [{:name => 'foo', :value => 123}, {:name => 'bar', :value => 456}]}
       Librato::Metrics.persister.persisted.should eql expected
     end

   end

  end

end