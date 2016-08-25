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
          it "sets to client" do
            barney = Client.new
            a = Aggregator.new(client: barney)
            expect(a.client).to eq(barney)
          end
        end

        context "without specified client" do
          it "uses Librato::Metrics client" do
            a = Aggregator.new
            expect(a.client).to eq(Librato::Metrics.client)
          end
        end

        context "with specified source" do
          it "sets to source" do
            a = Aggregator.new(source: 'rubble')
            expect(a.source).to eq('rubble')
          end
        end

        context "without specified source" do
          it "does not have a source" do
            a = Aggregator.new
            expect(a.source).to be_nil
          end
        end

        context "with valid arguments" do
          it "initializes Aggregator" do
            expect { Aggregator.new }.not_to raise_error
            expect { Aggregator.new(source: "metrics-web-stg-1") }.not_to raise_error
            expect { Aggregator.new(tags: { hostname: "metrics-web-stg-1" }) }.not_to raise_error
          end
        end

        context "with invalid arguments" do
          it "raises exception" do
            expect {
              Aggregator.new(
                source: "metrics-web-stg-1",
                tags: { hostname: "metrics-web-stg-1" }
              )
            }.to raise_error(ArgumentError)
            expect { Aggregator.new(measure_time: Time.now, time: Time.now) }.to raise_error(ArgumentError)
            expect { Aggregator.new(source: "metrics-web-stg-1", time: Time.now) }.to raise_error(ArgumentError)
            expect {
              Aggregator.new(
                measure_time: Time.now,
                tags: { hostname: "metrics-web-stg-1" }
              )
            }.to raise_error(ArgumentError)
          end
        end
      end

      describe "#add" do
        it "allows chaining" do
          expect(subject.add(foo: 1234)).to eq(subject)
        end

        context "with invalid arguments" do
          it "raises exception" do
            expect {
              subject.add test: { source: "metrics-web-stg-1", tags: { hostname: "metrics-web-stg-1" }, value: 123 }
            }.to raise_error(ArgumentError)
            expect {
              subject.add test: { measure_time: Time.now, time: Time.now, value: 123 }
            }.to raise_error(ArgumentError)
            expect {
              subject.add test: { source: "metrics-web-stg-1", time: Time.now, value: 123 }
            }.to raise_error(ArgumentError)
            expect {
              subject.add test: { tags: { hostname: "metrics-web-stg-1" }, measure_time: Time.now, value: 123 }
            }.to raise_error(ArgumentError)
            expect {
              subject.add test: { type: "gauge", tags: { hostname: "metrics-web-stg-1" }, value: 123 }
            }.to raise_error(ArgumentError)
          end
        end

        context "with single hash argument" do
          it "records a single aggregate" do
            subject.add foo: 3000
            expected = { #measure_time: @time, TODO: support specific time
                gauges: [
                { name: 'foo',
                  count: 1,
                  sum: 3000.0,
                  min: 3000.0,
                  max: 3000.0}
                ]
            }
            expect(subject.queued).to equal_unordered(expected)
          end

          it "aggregates multiple measurements" do
            subject.add foo: 1
            subject.add foo: 2
            subject.add foo: 3
            subject.add foo: 4
            subject.add foo: 5
            expected = { gauges: [
                { name: 'foo',
                  count: 5,
                  sum: 15.0,
                  min: 1.0,
                  max: 5.0}
                ]
            }
            expect(subject.queued).to equal_unordered(expected)
          end

          it "respects source argument" do
            subject.add foo: {source: 'alpha', value: 1}
            subject.add foo: 5
            subject.add foo: {source: :alpha, value: 6}
            subject.add foo: 10
            expected = { gauges: [
              { name: 'foo', source: 'alpha', count: 2,
                sum: 7.0, min: 1.0, max: 6.0 },
              { name: 'foo', count: 2,
                sum: 15.0, min: 5.0, max: 10.0 }
            ]}
            expect(subject.queued).to equal_unordered(expected)
          end

          context "when multidimensional is true" do
            it "maintains specified tags" do
              subject.add test: { tags: { db: "rr1" }, value: 1 }
              subject.add test: 5
              subject.add test: { tags: { db: "rr1" }, value: 6 }
              subject.add test: 10
              expected = {
                measurements: [
                  { name: "test", tags: { db: "rr1" }, count: 2, sum: 7.0, min: 1.0, max: 6.0 },
                  { name: "test", count: 2, sum: 15.0, min: 5.0, max: 10.0 }
                ]
              }

              expect(subject.queued).to equal_unordered(expected)
            end
          end

          context "with a prefix set" do
            it "auto-prepends names" do
              subject = Aggregator.new(prefix: 'foo')
              subject.add bar: 1
              subject.add bar: 12
              expected = {gauges: [
                { name:'foo.bar',
                  count: 2,
                  sum: 13.0,
                  min: 1.0,
                  max: 12.0
                  }
                ]
              }
              expect(subject.queued).to equal_unordered(expected)
            end
          end
        end

        context "with multiple hash arguments" do
          it "records a single aggregate" do
            subject.add foo: 3000
            subject.add bar: 30
            expected = {
              #measure_time: @time, TODO: support specific time
              gauges: [
                { name: 'foo',
                  count: 1,
                  sum: 3000.0,
                  min: 3000.0,
                  max: 3000.0},
                { name: 'bar',
                  count: 1,
                  sum: 30.0,
                  min: 30.0,
                  max: 30.0},
                ]
            }
            expect(subject.queued).to equal_unordered(expected)
          end

          it "aggregates multiple measurements" do
            subject.add foo: 1
            subject.add foo: 2
            subject.add foo: 3
            subject.add foo: 4
            subject.add foo: 5

            subject.add bar: 6
            subject.add bar: 7
            subject.add bar: 8
            subject.add bar: 9
            subject.add bar: 10
            expected = { gauges: [
                { name: 'foo',
                  count: 5,
                  sum: 15.0,
                  min: 1.0,
                  max: 5.0},
                { name: 'bar',
                  count: 5,
                  sum: 40.0,
                  min: 6.0,
                  max: 10.0}
                ]
            }
            expect(subject.queued).to equal_unordered(expected)
          end
        end
      end

      describe "#queued" do
        it "includes global source if set" do
          a = Aggregator.new(source: 'blah')
          a.add foo: 12
          expect(a.queued[:source]).to eq('blah')
        end

        it "includes global measure_time if set" do
          measure_time = (Time.now-1000).to_i
          a = Aggregator.new(measure_time: measure_time)
          a.add foo: 12
          expect(a.queued[:measure_time]).to eq(measure_time)
        end

        context "when tags are set" do
          it "includes global tags" do
            expected_tags = { region: "us-east-1" }
            subject = Aggregator.new(tags: expected_tags)
            subject.add test: 5

            expect(subject.queued[:tags]).to eq(expected_tags)
          end
        end

        context "when time is set" do
          it "includes global time" do
            expected_time = (Time.now-1000).to_i
            subject = Aggregator.new(time: expected_time)
            subject.add test: 10

            expect(subject.queued[:time]).to eq(expected_time)
          end
        end
      end

      describe "#submit" do
        before(:all) do
          Librato::Metrics.authenticate 'me@librato.com', 'foo'
          Librato::Metrics.persistence = :test
        end

        context "when successful" do
          it "flushes queued metrics and return true" do
            subject.add steps: 2042, distance: 1234
            expect(subject.submit).to be true
            expect(subject.empty?).to be true
          end
        end

        context "when failed" do
          it "preserves queue and return false" do
            subject.add steps: 2042, distance: 1234
            subject.persister.return_value(false)
            expect(subject.submit).to be false
            expect(subject.empty?).to be false
          end
        end
      end

      describe "#time" do
        context "with metric name only" do
          it "queues metric with timed value" do
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

          it "returns the result of the block" do
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

        it "does not submit immediately" do
          timed_agg = Aggregator.new(client: client, autosubmit_interval: 1)
          timed_agg.add foo: 1
          expect(timed_agg.persister.persisted).to be_nil # nothing sent
        end

        it "submits after interval" do
          timed_agg = Aggregator.new(client: client, autosubmit_interval: 1)
          timed_agg.add foo: 1
          sleep 1
          timed_agg.add foo: 2
          expect(timed_agg.persister.persisted).not_to be_nil # sent
        end
      end

    end

  end
end
