require "spec_helper"

module Librato
  module Metrics

    describe Queue do

      before(:each) do
        @time = (Time.now.to_i - 1*60)
        Queue.any_instance.stub(:epoch_time).and_return(@time)
      end

      describe "initialization" do
        context "with specified client" do
          it "should set to client" do
            barney = Client
            queue = Queue.new(:client => barney)
            queue.client.should be barney
          end
        end

        context "without specified client" do
          it "should use Librato::Metrics client" do
            queue = Queue.new
            queue.client.should be Librato::Metrics.client
          end
        end
      end

      describe "#add" do
        it "should allow chaining" do
          subject.add(:foo => 123).should == subject
        end

        context "with single hash argument" do
          it "should record a key-value gauge" do
            expected = {:gauges => [{:name => 'foo', :value => 3000, :measure_time => @time}]}
            subject.add :foo => 3000
            subject.queued.should equal_unordered(expected)
          end
        end

        context "with specified metric type" do
          it "should record counters" do
            subject.add :total_visits => {:type => :counter, :value => 4000}
            expected = {:counters => [{:name => 'total_visits', :value => 4000, :measure_time => @time}]}
            subject.queued.should equal_unordered(expected)
          end

          it "should record gauges" do
            subject.add :temperature => {:type => :gauge, :value => 34}
            expected = {:gauges => [{:name => 'temperature', :value => 34, :measure_time => @time}]}
            subject.queued.should equal_unordered(expected)
          end

          it "should accept type key as string or a symbol" do
            subject.add :total_visits => {"type" => "counter", :value => 4000}
            expected = {:counters => [{:name => 'total_visits', :value => 4000, :measure_time => @time}]}
            subject.queued.should equal_unordered(expected)
          end
        end

        context "with extra attributes" do
          it "should record" do
            measure_time = Time.now
            subject.add :disk_use => {:value => 35.4, :period => 2,
              :description => 'current disk utilization', :measure_time => measure_time,
              :source => 'db2'}
            expected = {:gauges => [{:value => 35.4, :name => 'disk_use', :period => 2,
              :description => 'current disk utilization', :measure_time => measure_time.to_i,
              :source => 'db2'}]}
            subject.queued.should equal_unordered(expected)
          end

          context "with a prefix set" do
            it "should auto-prepend names" do
              subject = Queue.new(:prefix => 'foo')
              subject.add :bar => 1
              subject.add :baz => {:value => 23}
              expected = {:gauges => [{:name =>'foo.bar', :value => 1, :measure_time => @time},
                                      {:name => 'foo.baz', :value => 23, :measure_time => @time}]}
              subject.queued.should equal_unordered(expected)
            end
          end

          context "when dynamically changing prefix" do
            it "should auto-append names" do
              subject.add :bar => 12
              subject.prefix = 'foo' # with string
              subject.add :bar => 23
              subject.prefix = :foo  # with symbol
              subject.add :bar => 34
              subject.prefix = nil   # unsetting
              subject.add :bar => 45
              expected = {:gauges => [
                {:name => 'bar', :value => 12, :measure_time => @time},
                {:name => 'foo.bar', :value => 23, :measure_time => @time},
                {:name => 'foo.bar', :value => 34, :measure_time => @time},
                {:name => 'bar', :value => 45, :measure_time => @time}]}
              subject.queued.should equal_unordered(expected)
            end
          end
        end

        context "with multiple metrics" do
          it "should record" do
            subject.add :foo => 123, :bar => 345, :baz => 567
            expected = {:gauges=>[{:name=>"foo", :value=>123, :measure_time => @time},
                                  {:name=>"bar", :value=>345, :measure_time => @time},
                                  {:name=>"baz", :value=>567, :measure_time => @time}]}
            subject.queued.should equal_unordered(expected)
          end
        end

        context "with a measure_time" do
          it "should accept time objects" do
            time = Time.now-5
            subject.add :foo => {:measure_time => time, :value => 123}
            subject.queued[:gauges][0][:measure_time].should == time.to_i
          end

          it "should accept integers" do
            time = @time.to_i
            subject.add :foo => {:measure_time => time, :value => 123}
            subject.queued[:gauges][0][:measure_time].should == time
          end

          it "should accept strings" do
            time = @time.to_s
            subject.add :foo => {:measure_time => time, :value => 123}
            subject.queued[:gauges][0][:measure_time].should == time.to_i
          end

          it "should raise exception in invalid time" do
            lambda {
              subject.add :foo => {:measure_time => '12', :value => 123}
            }.should raise_error(InvalidMeasureTime)
          end
        end
      end

      describe "#counters" do
        it "should return currently queued counters" do
          subject.add :transactions => {:type => :counter, :value => 12345},
                      :register_cents => {:type => :gauge, :value => 211101}
          subject.counters.should eql [{:name => 'transactions', :value => 12345, :measure_time => @time}]
        end

        it "should return [] when no queued counters" do
          subject.counters.should eql []
        end
      end

      describe "#empty?" do
        it "should return true when nothing queued" do
          subject.empty?.should be_true
        end

        it "should return false with queued items" do
          subject.add :foo => {:type => :gauge, :value => 121212}
          subject.empty?.should be_false
        end
      end

      describe "#gauges" do
        it "should return currently queued gauges" do
          subject.add :transactions => {:type => :counter, :value => 12345},
                        :register_cents => {:type => :gauge, :value => 211101}
          subject.gauges.should eql [{:name => 'register_cents', :value => 211101, :measure_time => @time}]
        end

        it "should return [] when no queued gauges" do
          subject.gauges.should eql []
        end
      end

      describe "#last_submit_time" do
        before(:all) do
          Librato::Metrics.authenticate 'me@librato.com', 'foo'
          Librato::Metrics.persistence = :test
        end

        it "should default to nil" do
          subject.last_submit_time.should be_nil
        end

        it "should store last submission time" do
          prior = Time.now
          subject.add :foo => 123
          subject.submit
          subject.last_submit_time.should >= prior
        end
      end

      describe "#merge!" do
        context "with another queue" do
          it "should merge gauges" do
            q1 = Queue.new
            q1.add :foo => 123, :bar => 456
            q2 = Queue.new
            q2.add :baz => 678
            q2.merge!(q1)
            expected = {:gauges=>[{:name=>"foo", :value=>123, :measure_time => @time},
                                  {:name=>"bar", :value=>456, :measure_time => @time},
                                  {:name=>"baz", :value=>678, :measure_time => @time}]}
            q2.queued.should equal_unordered(expected)
          end

          it "should merge counters" do
            q1 = Queue.new
            q1.add :users => {:type => :counter, :value => 1000}
            q1.add :sales => {:type => :counter, :value => 250}
            q2 = Queue.new
            q2.add :signups => {:type => :counter, :value => 500}
            q2.merge!(q1)
            expected = {:counters=>[{:name=>"users", :value=>1000, :measure_time => @time},
                                    {:name=>"sales", :value=>250, :measure_time => @time},
                                    {:name=>"signups", :value=>500, :measure_time => @time}]}
            q2.queued.should equal_unordered(expected)
          end

          it "should maintain specified sources" do
            q1 = Queue.new
            q1.add :neo => {:source => 'matrix', :value => 123}
            q2 = Queue.new(:source => 'red_pill')
            q2.merge!(q1)
            q2.queued[:gauges][0][:source].should == 'matrix'
          end

          it "should not change default source" do
            q1 = Queue.new(:source => 'matrix')
            q1.add :neo => 456
            q2 = Queue.new(:source => 'red_pill')
            q2.merge!(q1)
            q2.queued[:source].should == 'red_pill'
          end

          it "should track previous default source" do
            q1 = Queue.new(:source => 'matrix')
            q1.add :neo => 456
            q2 = Queue.new(:source => 'red_pill')
            q2.add :morpheus => 678
            q2.merge!(q1)
            q2.queued[:gauges].each do |gauge|
              if gauge[:name] == 'neo'
                gauge[:source].should == 'matrix'
              end
            end
          end

          it "should handle empty cases" do
            q1 = Queue.new
            q1.add :foo => 123, :users => {:type => :counter, :value => 1000}
            q2 = Queue.new
            q2.merge!(q1)
            expected = {:counters => [{:name=>"users", :value=>1000, :measure_time => @time}],
                        :gauges => [{:name=>"foo", :value=>123, :measure_time => @time}]}
            q2.queued.should == expected
          end
        end

        context "with an aggregator" do
          it "should merge" do
            aggregator = Aggregator.new(:source => 'aggregator')
            aggregator.add :timing => 102
            aggregator.add :timing => 203
            queue = Queue.new(:source => 'queue')
            queue.add :gauge => 42
            queue.merge!(aggregator)
            expected = {:gauges=>[{:name=>"gauge", :value=>42, :measure_time=>@time},
                                  {:name=>"timing", :count=>2, :sum=>305.0, :min=>102.0, :max=>203.0, :source=>"aggregator"}],
                        :source=>'queue'}
            queue.queued.should equal_unordered(expected)

          end
        end

        context "with a hash" do
          it "should merge" do
            to_merge = {:gauges=>[{:name => 'foo', :value => 123}],
                        :counters=>[{:name => 'bar', :value => 456}]}
            q = Queue.new
            q.merge!(to_merge)
            q.gauges.length.should == 1
            q.counters.length.should == 1
          end
        end
      end

      describe "#per_request" do
        it "should default to 500" do
          subject.per_request.should == 500
        end
      end

      describe "#queued" do
        it "should include global source if set" do
          q = Queue.new(:source => 'blah')
          q.add :foo => 12
          q.queued[:source].should == 'blah'
        end

        it "should include global measure_time if set" do
          measure_time = (Time.now-1000).to_i
          q = Queue.new(:measure_time => measure_time)
          q.add :foo => 12
          q.queued[:measure_time].should == measure_time
        end
      end

      describe "#size" do
        it "should return empty if gauges and counters are emtpy" do
          subject.size.should eq 0
        end
        it "should return count of gauges and counters if added" do
          subject.add :transactions => {:type => :counter, :value => 12345},
              :register_cents => {:type => :gauge, :value => 211101}
          subject.add :transactions => {:type => :counter, :value => 12345},
                      :register_cents => {:type => :gauge, :value => 211101}
          subject.size.should eql 4
        end
      end

      describe "#submit" do
        before(:all) do
          Librato::Metrics.authenticate 'me@librato.com', 'foo'
          Librato::Metrics.persistence = :test
        end

        context "when successful" do
          it "should flush queued metrics and return true" do
            subject.add :steps => 2042, :distance => 1234
            subject.submit.should be_true
            subject.queued.should be_empty
          end
        end

        context "when failed" do
          it "should preserve queue and return false" do
            subject.add :steps => 2042, :distance => 1234
            subject.persister.return_value(false)
            subject.submit.should be_false
            subject.queued.should_not be_empty
          end
        end
      end

      describe "#time" do
        context "with metric name only" do
          it "should queue metric with timed value" do
            subject.time :sleeping do
              sleep 0.1
            end
            queued = subject.queued[:gauges][0]
            queued[:name].should == 'sleeping'
            queued[:value].should be >= 100
            queued[:value].should be_within(30).of(100)
          end
        end

        context "with metric and options" do
          it "should queue metric with value and options" do
            subject.time :sleep_two, :source => 'app1', :period => 2 do
              sleep 0.05
            end
            queued = subject.queued[:gauges][0]
            queued[:name].should == 'sleep_two'
            queued[:period].should == 2
            queued[:source].should == 'app1'
            queued[:value].should be >= 50
            queued[:value].should be_within(30).of(50)
          end
        end
      end

    end # Queue

  end
end
