require 'spec_helper'

module Librato

  describe Metrics do

   describe "#authorize" do

     context "when given two arguments" do
       it "should store them on simple" do
         Metrics.authenticate 'tester@librato.com', 'api_key'
         Metrics::Simple.email.should == 'tester@librato.com'
         Metrics::Simple.api_key.should == 'api_key'
       end
     end

   end

   describe "#list" do

     context "without arguments" do

       it "should list all metrics"

     end

     context "with a name argument" do

       it "should list metrics that match"

     end

   end

   describe "#persistence" do

     it "should allow configuration of persistence method" do
       Metrics.persistence = :test
       Metrics.persistence.should == :test
     end

   end

   describe "#submit" do

     it "should persist metrics immediately" do
       Metrics.persistence = :test
       Metrics.submit(:foo => 123).should eql true
       Metrics.persister.persisted.should eql({:gauges => [{:name => 'foo', :value => 123}]})
     end

   end

  end

end