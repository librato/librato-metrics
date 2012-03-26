require "spec_helper.rb"
module Librato
  module Metrics

    describe Aggregate do

      before(:all) do
        @time = Time.now.to_i
        Aggregate.stub(:epoch_time).and_return(@time)
      end

      describe "initialization" do
        context "with specified client" do
          it "should set to client" do
            barney = Client
            a = Aggregate.new(:client => barney)
            a.client.should be barney
          end
        end

        context "without specified client" do
          it "should use Librato::Metrics client" do
            a = Aggregate.new
            a.client.should be Librato::Metrics.client
          end
        end

        context "with specified source" do
          it "should set to source" do
            a = Aggregate.new(:source => 'rubble')
            a.source.should == 'rubble'
          end
        end

        context "without specified source" do
          it "should not have a source" do
            a = Aggregate.new
            a.source.should be nil
          end
        end
      end

      describe "#add" do
        context "with single hash argument" do
          it "should record a single aggregate" do
            subject.add :foo => 3000
            subject.queued.should eql(
              { #:measure_time => @time, TODO: support specific time
                :gauges => [
                { :name => 'foo',
                  :count => 1,
                  :sum => 3000.0,
                  :min => 3000.0,
                  :max => 3000.0}
                ]
            })
          end

          it "should aggregate multiple measurements" do
            subject.add :foo => 1
            subject.add :foo => 2
            subject.add :foo => 3
            subject.add :foo => 4
            subject.add :foo => 5
            subject.queued.should eql(
              { :gauges => [
                { :name => 'foo',
                  :count => 5,
                  :sum => 15.0,
                  :min => 1.0,
                  :max => 5.0}
                ]
            })
          end
        end

        context "with multiple hash arguments" do
          it "should record a single aggregate" do
            subject.add :foo => 3000
            subject.add :bar => 30
            subject.queued.should eql(
              { #:measure_time => @time, TODO: support specific time
                :gauges => [
                { :name => 'foo',
                  :count => 1,
                  :sum => 3000.0,
                  :min => 3000.0,
                  :max => 3000.0},
                { :name => 'bar',
                  :count => 1,
                  :sum => 30.0,
                  :min => 30.0,
                  :max => 30.0},
                ]
            })
          end

          it "should aggregate multiple measurements" do
            subject.add :foo => 1
            subject.add :foo => 2
            subject.add :foo => 3
            subject.add :foo => 4
            subject.add :foo => 5

            subject.add :bar => 6
            subject.add :bar => 7
            subject.add :bar => 8
            subject.add :bar => 9
            subject.add :bar => 10
            subject.queued.should eql(
              { :gauges => [
                { :name => 'foo',
                  :count => 5,
                  :sum => 15.0,
                  :min => 1.0,
                  :max => 5.0},
                { :name => 'bar',
                  :count => 5,
                  :sum => 40.0,
                  :min => 6.0,
                  :max => 10.0}
                ]
            })
          end
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
            subject.empty?.should be_true
          end
        end

        context "when failed" do
          it "should preserve queue and return false" do
            subject.add :steps => 2042, :distance => 1234
            subject.persister.return_value(false)
            subject.submit.should be_false
            subject.empty?.should be_false
          end
        end
      end

      describe "#time" do
        context "with metric name only" do
          it "should queue metric with timed value" do
            1.upto(5) do
              subject.time :sleeping do
                sleep 0.1
              end
            end
            queued = subject.queued[:gauges][0]
            queued[:name].should == 'sleeping'
            queued[:count].should be 5
            queued[:sum].should be > 500
            queued[:sum].should be_within(150).of(500)
          end
        end
      end

    end

  end
end
