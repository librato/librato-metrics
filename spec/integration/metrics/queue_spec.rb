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
          counter = Metrics.fetch :counter_3, :count => 1
          counter['unassigned'][0]['value'].should == 3
          gauge = Metrics.fetch :gauge_5, :count => 1
          gauge['unassigned'][0]['value'].should == 5
        end
      end

      it "should respect default and individual sources" do
        queue = Queue.new(:source => 'default')
        queue.add :foo => 123
        queue.add :bar => {:value => 456, :source => 'barsource'}
        queue.submit

        foo = Metrics.fetch :foo, :count => 2
        foo['default'][0]['value'].should == 123

        bar = Metrics.fetch :bar, :count => 2
        bar['barsource'][0]['value'].should == 456
      end

    end

  end
end
