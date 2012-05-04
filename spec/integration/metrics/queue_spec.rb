require 'spec_helper'

module Librato
  module Metrics
   
    describe Queue do
      before(:all) { prep_integration_tests }
      
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
          
          delete_all_metrics
          queue.submit
          
          metrics = Metrics.list
          metrics.length.should == 8
          counter = Metrics.fetch :counter_3, :count => 1
          counter['unassigned'][0]['value'].should == 3
          gauge = Metrics.fetch :gauge_5, :count => 1
          gauge['unassigned'][0]['value'].should == 5
        end
      end
    
      context "with a volume max" do
        it "should submit when the max is reached" do
          Middleware::CountRequests.reset
          vol_queue = Queue.new(:autosubmit_count => 2)
          vol_queue.add :foo => 1
          vol_queue.add :bar => 2
          Middleware::CountRequests.total_requests.should == 1
        end
        
        it "should not submit if the max has not been reached" do
          Middleware::CountRequests.reset
          vol_queue = Queue.new(:autosubmit_count => 5)
          vol_queue.add :foo => 1
          vol_queue.add :bar => 2
          Middleware::CountRequests.total_requests.should == 0
        end
      end
    end
    
  end
end
