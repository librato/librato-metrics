require 'spec_helper'

module Librato
  describe Metrics do
    before(:all) { prep_integration_tests }

    describe "#delete" do
      before(:each) { delete_all_metrics }

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
          Metrics.submit :foo => 123, :bar => 345, :baz => 567
          Metrics.delete :foo, :bar
          Metrics.list(:name => :foo).should be_empty
          Metrics.list(:name => :bar).should be_empty
          Metrics.list(:name => :baz).should_not be_empty
        end
      end

      context "with missing metric" do
        it "should run cleanly" do
          # the API currently returns success even if
          # the metric has already been deleted or is absent.
          Metrics.delete :missing
        end
      end

      context "with no arguments" do
        it "should not make request" do
          lambda {
            Metrics.delete
          }.should raise_error(Metrics::NoMetricsProvided)
        end
      end
    end

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

      it "should not retain errors" do
        delete_all_metrics
        Metrics.submit :foo => {:type => :counter, :value => 12}
        lambda {
          Metrics.submit :foo => 15 # submitting as gauge
        }.should raise_error
        lambda {
          Metrics.submit :foo => {:type => :counter, :value => 17}
        }.should_not raise_error
      end

    end

    describe "#update" do

      context "with existing metric" do
        before do
          delete_all_metrics
          Metrics.submit :foo => 123
        end

        it "should upate the metric" do
          Metrics.update :foo, :display_name => "Foo Metric",
                               :period => 15,
                               :attributes => {
                                 :display_max => 1000
                               }
          foo = Metrics.fetch :foo
          foo['display_name'].should == 'Foo Metric'
          foo['period'].should == 15
          foo['attributes'].should == {'display_max' => 1000}
        end
      end

      context "without an existing metric" do
        it "should create the metric if type specified" do
          delete_all_metrics
          Metrics.update :foo, :display_name => "Foo Metric",
                               :type => :gauge,
                               :period => 15,
                               :attributes => {
                                 :display_max => 1000
                               }
          foo = Metrics.fetch :foo
          foo['display_name'].should == 'Foo Metric'
          foo['period'].should == 15
          foo['attributes'].should == {'display_max' => 1000}
        end

        it "should raise error if no type specified" do
          delete_all_metrics
          lambda {
            Metrics.update :foo, :display_name => "Foo Metric",
                                 :period => 15,
                                 :attributes => {
                                   :display_max => 1000
                                 }
          }.should raise_error
        end
      end

    end

  end
end