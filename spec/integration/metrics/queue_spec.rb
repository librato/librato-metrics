require 'spec_helper'

module Librato
  module Metrics

    describe Queue do
      before(:all) { prep_integration_tests }
      before(:each) { delete_all_metrics }

      context "with a large number of metrics" do
        it "should submit them in multiple requests" do
          Middleware::CountRequests.reset
          queue = Queue.new(:per_request => 3)
          (1..10).each do |i|
            queue.add "gauge_#{i}" => 1
          end
          queue.submit
          Middleware::CountRequests.total_requests.should == 4
        end

        it "should persist all metrics" do
          queue = Queue.new(:per_request => 2)
          (1..5).each do |i|
            queue.add "gauge_#{i}" => i
          end
          (1..3).each do |i|
            queue.add "counter_#{i}" => {:type => :counter, :value => i}
          end
          queue.submit

          metrics = Metrics.list
          metrics.length.should == 8
          counter = Metrics.get_measurements :counter_3, :count => 1
          counter['unassigned'][0]['value'].should == 3
          gauge = Metrics.get_measurements :gauge_5, :count => 1
          gauge['unassigned'][0]['value'].should == 5
        end

        it "should apply globals to each request" do
          source = 'yogi'
          measure_time = Time.now.to_i-3
          queue = Queue.new(
            :per_request => 3,
            :source => source,
            :measure_time => measure_time,
            :skip_measurement_times => true
          )
          (1..5).each do |i|
            queue.add "gauge_#{i}" => 1
          end
          queue.submit

          # verify globals have persisted for all requests
          gauge = Metrics.get_measurements :gauge_5, :count => 1
          gauge[source][0]["value"].should eq(1.0)
          gauge[source][0]["measure_time"].should eq(measure_time)
        end
      end

      it "should respect default and individual sources" do
        queue = Queue.new(:source => 'default')
        queue.add :foo => 123
        queue.add :bar => {:value => 456, :source => 'barsource'}
        queue.submit

        foo = Metrics.get_measurements :foo, :count => 2
        foo['default'][0]['value'].should == 123

        bar = Metrics.get_measurements :bar, :count => 2
        bar['barsource'][0]['value'].should == 456
      end

    end

  end
end
