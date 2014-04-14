require "spec_helper"

module Librato
  module Metrics

    describe Queue do

      let(:client) { Client.new.tap{ |c| c.persistence = :test } }

      context "with an autosubmit count" do
        it "should submit when the max is reached" do
          vol_queue = Queue.new(:client => client, :autosubmit_count => 2)
          vol_queue.add :foo => 1
          vol_queue.add :bar => 2
          vol_queue.persister.persisted.should_not be_nil # sent
        end

        it "should not submit if the max has not been reached" do
          vol_queue = Queue.new(:client => client, :autosubmit_count => 5)
          vol_queue.add :foo => 1
          vol_queue.add :bar => 2
          vol_queue.persister.persisted.should be_nil # nothing sent
        end

        it 'should submit when merging' do
          queue = Queue.new(:client => client, :autosubmit_count => 5)
          (1..3).each {|i| queue.add "metric_#{i}" => 1 }

          to_merge = Queue.new(:client => client)
          (1..5).each {|i| to_merge.add "metric_#{i}" => 1 }

          queue.merge!(to_merge)

          queue.persister.persisted[:gauges].length.should == 8
          queue.queued.should be_empty
        end
      end

      context "with an autosubmit interval" do
        it "should not submit immediately" do
          vol_queue = Queue.new(:client => client, :autosubmit_interval => 1)
          vol_queue.add :foo => 1
          vol_queue.persister.persisted.should be_nil # nothing sent
        end

        it "should submit after interval" do
          vol_queue = Queue.new(:client => client, :autosubmit_interval => 1)
          vol_queue.add :foo => 1
          sleep 1
          vol_queue.add :foo => 2
          vol_queue.persister.persisted.should_not be_nil # sent
        end
      end

    end
  end
end