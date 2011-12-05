require "spec_helper.rb"

module Librato
  module Metrics

    describe MetricSet do

      describe "#counters" do

        it "should return currently queued counters" do
          subject.queue :transactions => {:type => :counter, :value => 12345},
                        :register_cents => {:type => :gauge, :value => 211101}
          subject.counters.should eql [{:name => 'transactions', :value => 12345}]
        end

        it "should return [] when no queued counters" do
          subject.counters.should eql []
        end

      end

      describe "#gauges" do

        it "should return currently queued gauges" do
          subject.queue :transactions => {:type => :counter, :value => 12345},
                        :register_cents => {:type => :gauge, :value => 211101}
          subject.gauges.should eql [{:name => 'register_cents', :value => 211101}]
        end

        it "should return [] when no queued gauges" do
          subject.gauges.should eql []
        end

      end

      describe "#queue" do

        context "with single hash argument" do
          it "should record a key-value gauge" do
            subject.queue :foo => 3000
            subject.queued.should eql({:gauges => [{:name => 'foo', :value => 3000}]})
          end
        end

        context "with specified metric type" do
          it "should record counters" do
            subject.queue :total_visits => {:type => :counter, :value => 4000}
            expected = {:counters => [{:name => 'total_visits', :value => 4000}]}
            subject.queued.should eql expected
          end

          it "should record gauges" do
            subject.queue :temperature => {:type => :gauge, :value => 34}
            expected = {:gauges => [{:name => 'temperature', :value => 34}]}
            subject.queued.should eql expected
          end
        end

        context "with extra attributes" do
          it "should record" do
            measure_time = Time.now
            subject.queue :disk_use => {:value => 35.4, :period => 2,
              :description => 'current disk utilization', :measure_time => measure_time,
              :source => 'db2'}
            expected = {:gauges => [{:value => 35.4, :name => 'disk_use', :period => 2,
              :description => 'current disk utilization', :measure_time => measure_time,
              :source => 'db2'}]}
            subject.queued.should eql expected
          end
        end

      end

    end # MetricSet

  end
end