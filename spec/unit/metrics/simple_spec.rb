require 'spec_helper'

module Librato
  module Metrics

    describe Simple do

      describe "#authenticate" do

        context "when given two arguments" do
          it "should store them as email and api_key" do
            Simple.authenticate 'test@librato.com', 'api_key'
            Simple.email.should == 'test@librato.com'
            Simple.api_key.should == 'api_key'
          end
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