require 'spec_helper'

module Librato
  describe Metrics do
    before(:all) { prep_integration_tests }

    pending "#fetch" do
    end

    describe "#list" do

      before(:all) do
        delete_all_metrics
        Metrics.submit :foo => 123, :bar => 345, :baz => 678, :foo_2 => 901
      end

      context "without arguments" do

        it "should list all metrics" do
          metric_names = Metrics.list.map { |metric| metric['name'] }
          metric_names.sort.should == %w{foo bar baz foo_2}.sort
        end

      end

      context "with a name argument" do

        it "should list metrics that match" do
          metric_names = Metrics.list(:name => 'foo').map { |metric| metric['name'] }
          metric_names.sort.should == %w{foo foo_2}.sort
        end

      end

    end

    describe "#submit" do

      context "with a gauge" do
        before(:all) do
          delete_all_metrics
          Metrics.submit :foo => 123
        end

        it "should create the metrics" do
          metric = Metrics.list[0]
          metric['name'].should == 'foo'
          metric['type'].should == 'gauge'
        end

        it "should store their data" do
          data = Metrics.fetch :foo, :count => 1
          data.should_not be_empty
          data['unassigned'][0]['value'] == 123.0
        end
      end

      context "with a counter" do
        before(:all) do
          delete_all_metrics
          Metrics.submit :bar => {:type => :counter, :source => 'baz', :value => 456}
        end

        it "should create the metrics" do
          metric = Metrics.list[0]
          metric['name'].should == 'bar'
          metric['type'].should == 'counter'
        end

        it "should store their data" do
          data = Metrics.fetch :bar, :count => 1
          data.should_not be_empty
          data['baz'][0]['value'] == 456.0
        end
      end

    end


  end
end