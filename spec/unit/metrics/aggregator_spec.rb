require "spec_helper.rb"
module Librato
  module Metrics

    describe Aggregator do

      before(:all) do
        @time = 1354720160 #Time.now.to_i
        allow_any_instance_of(Aggregator).to receive(:epoch_time).and_return(@time)
      end

      describe "initialization" do
        context "with specified client" do
          it "should set to client" do
            barney = Client.new
            a = Aggregator.new(:client => barney)
            expect(a.client).to eq(barney)
          end
        end

        context "without specified client" do
          it "should use Librato::Metrics client" do
            a = Aggregator.new
            expect(a.client).to eq(Librato::Metrics.client)
          end
        end

        context "with specified source" do
          it "should set to source" do
            a = Aggregator.new(:source => 'rubble')
            expect(a.source).to eq('rubble')
          end
        end

        context "without specified source" do
          it "should not have a source" do
            a = Aggregator.new
            expect(a.source).to be_nil
          end
        end
      end

      describe "#add" do
        it "should allow chaining" do
          expect(subject.add(:foo => 1234)).to eq(subject)
        end

        context "with single hash argument" do
          it "should record a single aggregate" do
            subject.add :foo => 3000
            expected = { #:measure_time => @time, TODO: support specific time
                :gauges => [
                { :name => 'foo',
                  :count => 1,
                  :sum => 3000.0,
                  :min => 3000.0,
                  :max => 3000.0}
                ]
            }
            expect(subject.queued).to equal_unordered(expected)
          end

          it "should aggregate multiple measurements" do
            subject.add :foo => 1
            subject.add :foo => 2
            subject.add :foo => 3
            subject.add :foo => 4
            subject.add :foo => 5
            expected = { :gauges => [
                { :name => 'foo',
                  :count => 5,
                  :sum => 15.0,
                  :min => 1.0,
                  :max => 5.0}
                ]
            }
            expect(subject.queued).to equal_unordered(expected)
          end

          it "should respect source argument" do
            subject.add :foo => {:source => 'alpha', :value => 1}
            subject.add :foo => 5
            subject.add :foo => {:source => :alpha, :value => 6}
            subject.add :foo => 10
            expected = { :gauges => [
              { :name => 'foo', :source => 'alpha', :count => 2,
                :sum => 7.0, :min => 1.0, :max => 6.0 },
              { :name => 'foo', :count => 2,
                :sum => 15.0, :min => 5.0, :max => 10.0 }
            ]}
            expect(subject.queued).to equal_unordered(expected)
          end

          context "with a prefix set" do
            it "should auto-prepend names" do
              subject = Aggregator.new(:prefix => 'foo')
              subject.add :bar => 1
              subject.add :bar => 12
              expected = {:gauges => [
                { :name =>'foo.bar',
                  :count => 2,
                  :sum => 13.0,
                  :min => 1.0,
                  :max => 12.0
                  }
                ]
              }
              expect(subject.queued).to equal_unordered(expected)
            end
          end
        end

        context "with multiple hash arguments" do
          it "should record a single aggregate" do
            subject.add :foo => 3000
            subject.add :bar => 30
            expected = {
              #:measure_time => @time, TODO: support specific time
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
            }
            expect(subject.queued).to equal_unordered(expected)
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
            expected = { :gauges => [
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
            }
            expect(subject.queued).to equal_unordered(expected)
          end
        end
      end

      describe "#queued" do
        it "should include global source if set" do
          a = Aggregator.new(:source => 'blah')
          a.add :foo => 12
          expect(a.queued[:source]).to eq('blah')
        end

        it "should include global measure_time if set" do
          measure_time = (Time.now-1000).to_i
          a = Aggregator.new(:measure_time => measure_time)
          a.add :foo => 12
          expect(a.queued[:measure_time]).to eq(measure_time)
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
            expect(subject.submit).to be true
            expect(subject.empty?).to be true
          end
        end

        context "when failed" do
          it "should preserve queue and return false" do
            subject.add :steps => 2042, :distance => 1234
            subject.persister.return_value(false)
            expect(subject.submit).to be false
            expect(subject.empty?).to be false
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
            expect(queued[:name]).to eq('sleeping')
            expect(queued[:count]).to eq(5)
            expect(queued[:sum]).to be >= 500.0
            expect(queued[:sum]).to be_within(150).of(500)
          end

          it "should return the result of the block" do
            result = subject.time :returning do
              :hi_there
            end

            expect(result).to eq(:hi_there)
          end
        end
      end

      context "with an autosubmit interval" do
        let(:client) do
          client = Client.new
          client.persistence = :test
          client
        end

        it "should not submit immediately" do
          timed_agg = Aggregator.new(:client => client, :autosubmit_interval => 1)
          timed_agg.add :foo => 1
          expect(timed_agg.persister.persisted).to be_nil # nothing sent
        end

        it "should submit after interval" do
          timed_agg = Aggregator.new(:client => client, :autosubmit_interval => 1)
          timed_agg.add :foo => 1
          sleep 1
          timed_agg.add :foo => 2
          expect(timed_agg.persister.persisted).to_not be_nil # sent
        end
      end

    end

  end
end
