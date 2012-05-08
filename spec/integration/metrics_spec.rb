require 'spec_helper'

module Librato
  describe Metrics do
    before(:all) { prep_integration_tests }

    describe "#fetch" do
      before(:all) do
        delete_all_metrics
        Metrics.submit :my_counter => {:type => :counter, :value => 0, :measure_time => Time.now.to_i-60}
        1.upto(2).each do |i|
          measure_time = Time.now.to_i - (5+i)
          opts = {:measure_time => measure_time, :type => :counter}
          Metrics.submit :my_counter => opts.merge(:value => i)
          Metrics.submit :my_counter => opts.merge(:source => 'baz', :value => i+1)
        end
      end

      context "without arguments" do
        it "should get metric attributes" do
          metric = Metrics.fetch :my_counter
          metric['name'].should == 'my_counter'
          metric['type'].should == 'counter'
        end
      end

      context "with a start_time" do
        it "should return entries since that time" do
          data = Metrics.fetch :my_counter, :start_time => Time.now-3600 # 1 hr ago
          data['unassigned'].length.should == 3
          data['baz'].length.should == 2
        end
      end

      context "with a count limit" do
        it "should return that number of entries per source" do
          data = Metrics.fetch :my_counter, :count => 2
          data['unassigned'].length.should == 2
          data['baz'].length.should == 2
        end
      end

      context "with a source limit" do
        it "should only return that source" do
          data = Metrics.fetch :my_counter, :source => 'baz', :start_time => Time.now-3600
          data['baz'].length.should == 2
          data['unassigned'].should be_nil
        end
      end

    end

    describe "#delete" do
      before(:all) { delete_all_metrics }
      
      context "with a single argument" do
        it "should delete named metric" do
          Metrics.submit :foo => 123
          Metrics.list(:name => :foo).should_not be_empty
          Metrics.delete :foo
          Metrics.list(:name => :foo).should be_empty
        end
      end
      
      context "with multiple arguments" do
        it "should delete named metrics" do
          
        end
      end
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