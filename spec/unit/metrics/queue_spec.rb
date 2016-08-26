require "spec_helper"

module Librato
  module Metrics

    describe Queue do

      before(:each) do
        @time = (Time.now.to_i - 1*60)
        allow_any_instance_of(Queue).to receive(:epoch_time).and_return(@time)
      end

      describe "initialization" do
        context "with specified client" do
          it "sets to client" do
            barney = Client
            allow(barney).to receive(:has_tags?).and_return(false)
            queue = Queue.new(client: barney)
            expect(queue.client).to eq(barney)
          end
        end

        context "without specified client" do
          it "uses Librato::Metrics client" do
            queue = Queue.new
            expect(queue.client).to eq(Librato::Metrics.client)
          end
        end

        context "with valid arguments" do
          it "initializes Queue" do
            expect { Queue.new }.not_to raise_error
            expect { Queue.new(source: "metrics-web-stg-1") }.not_to raise_error
            expect { Queue.new(tags: { hostname: "metrics-web-stg-1" }) }.not_to raise_error
          end
        end

        context "with invalid arguments" do
          it "raises exception" do
            expect {
              Queue.new(
                source: "metrics-web-stg-1",
                tags: { hostname: "metrics-web-stg-1" }
              )
            }.to raise_error(InvalidParameters)
            expect { Queue.new(measure_time: Time.now, time: Time.now) }.to raise_error(InvalidParameters)
            expect { Queue.new(source: "metrics-web-stg-1", time: Time.now) }.to raise_error(InvalidParameters)
            expect {
              Queue.new(
                measure_time: Time.now,
                tags: { hostname: "metrics-web-stg-1" }
              )
            }.to raise_error(InvalidParameters)
          end
        end
      end

      describe "#add" do
        it "allows chaining" do
          expect(subject.add(foo: 123)).to eq(subject)
        end

        context "with invalid arguments" do
          it "raises exception" do
            expect {
              subject.add test: { source: "metrics-web-stg-1", tags: { hostname: "metrics-web-stg-1" }, value: 123 }
            }.to raise_error(InvalidParameters)
            expect {
              subject.add test: { measure_time: Time.now, time: Time.now, value: 123 }
            }.to raise_error(InvalidParameters)
            expect {
              subject.add test: { source: "metrics-web-stg-1", time: Time.now, value: 123 }
            }.to raise_error(InvalidParameters)
            expect {
              subject.add test: { tags: { hostname: "metrics-web-stg-1" }, measure_time: Time.now, value: 123 }
            }.to raise_error(InvalidParameters)
          end
        end

        context "with single hash argument" do
          it "records a key-value gauge" do
            expected = {gauges: [{name: 'foo', value: 3000, measure_time: @time}]}
            subject.add foo: 3000
            expect(subject.queued).to equal_unordered(expected)
          end
        end

        context "with specified metric type" do
          it "records counters" do
            subject.add total_visits: {type: :counter, value: 4000}
            expected = {counters: [{name: 'total_visits', value: 4000, measure_time: @time}]}
            expect(subject.queued).to equal_unordered(expected)
          end

          it "records gauges" do
            subject.add temperature: {type: :gauge, value: 34}
            expected = {gauges: [{name: 'temperature', value: 34, measure_time: @time}]}
            expect(subject.queued).to equal_unordered(expected)
          end

          it "accepts type key as string or a symbol" do
            subject.add total_visits: {type: "counter", value: 4000}
            expected = {counters: [{name: 'total_visits', value: 4000, measure_time: @time}]}
            expect(subject.queued).to equal_unordered(expected)
          end
        end

        context "with extra attributes" do
          it "records" do
            measure_time = Time.now
            subject.add disk_use: {value: 35.4, period: 2,
              description: 'current disk utilization', measure_time: measure_time,
              source: 'db2'}
            expected = {gauges: [{value: 35.4, name: 'disk_use', period: 2,
              description: 'current disk utilization', measure_time: measure_time.to_i,
              source: 'db2'}]}
            expect(subject.queued).to equal_unordered(expected)
          end

          context "with a prefix set" do
            it "auto-prepends names" do
              subject = Queue.new(prefix: 'foo')
              subject.add bar: 1
              subject.add baz: {value: 23}
              expected = {gauges: [{name:'foo.bar', value: 1, measure_time: @time},
                                      {name: 'foo.baz', value: 23, measure_time: @time}]}
              expect(subject.queued).to equal_unordered(expected)
            end
          end

          context "when dynamically changing prefix" do
            it "auto-appends names" do
              subject.add bar: 12
              subject.prefix = 'foo' # with string
              subject.add bar: 23
              subject.prefix = :foo  # with symbol
              subject.add bar: 34
              subject.prefix = nil   # unsetting
              subject.add bar: 45
              expected = {gauges: [
                {name: 'bar', value: 12, measure_time: @time},
                {name: 'foo.bar', value: 23, measure_time: @time},
                {name: 'foo.bar', value: 34, measure_time: @time},
                {name: 'bar', value: 45, measure_time: @time}]}
              expect(subject.queued).to equal_unordered(expected)
            end
          end
        end

        context "with multiple metrics" do
          it "records" do
            subject.add foo: 123, bar: 345, baz: 567
            expected = {gauges:[{name:"foo", value:123, measure_time: @time},
                                  {name:"bar", value:345, measure_time: @time},
                                  {name:"baz", value:567, measure_time: @time}]}
            expect(subject.queued).to equal_unordered(expected)
          end
        end

        context "with a measure_time" do
          it "accepts time objects" do
            time = Time.now-5
            subject.add foo: {measure_time: time, value: 123}
            expect(subject.queued[:gauges][0][:measure_time]).to eq(time.to_i)
          end

          it "accepts integers" do
            time = @time.to_i
            subject.add foo: {measure_time: time, value: 123}
            expect(subject.queued[:gauges][0][:measure_time]).to eq(time)
          end

          it "accepts strings" do
            time = @time.to_s
            subject.add foo: {measure_time: time, value: 123}
            expect(subject.queued[:gauges][0][:measure_time]).to eq(time.to_i)
          end

          it "raises exception in invalid time" do
            expect {
              subject.add foo: {measure_time: '12', value: 123}
            }.to raise_error(InvalidMeasureTime)
          end
        end
      end

      describe "#counters" do
        it "returns currently queued counters" do
          subject.add transactions: {type: :counter, value: 12345},
                      register_cents: {type: :gauge, value: 211101}
          expect(subject.counters).to eq([{name: 'transactions', value: 12345, measure_time: @time}])
        end

        it "returns [] when no queued counters" do
          expect(subject.counters).to be_empty
        end
      end

      describe "#empty?" do
        it "returns true when nothing queued" do
          expect(subject.empty?).to be true
        end

        it "returns false with queued items" do
          subject.add foo: {type: :gauge, value: 121212}
          expect(subject.empty?).to be false
        end
      end

      describe "#gauges" do
        it "returns currently queued gauges" do
          subject.add transactions: {type: :counter, value: 12345},
                        register_cents: {type: :gauge, value: 211101}
          expect(subject.gauges).to eq([{name: 'register_cents', value: 211101, measure_time: @time}])
        end

        it "returns [] when no queued gauges" do
          expect(subject.gauges).to be_empty
        end
      end

      describe "#last_submit_time" do
        before(:all) do
          Librato::Metrics.authenticate 'me@librato.com', 'foo'
          Librato::Metrics.persistence = :test
        end

        it "defaults to nil" do
          expect(subject.last_submit_time).to be_nil
        end

        it "stores last submission time" do
          prior = Time.now
          subject.add foo: 123
          subject.submit
          expect(subject.last_submit_time).to be >= prior
        end
      end

      describe "#merge!" do
        context "with another queue" do
          it "merges gauges" do
            q1 = Queue.new
            q1.add foo: 123, bar: 456
            q2 = Queue.new
            q2.add baz: 678
            q2.merge!(q1)
            expected = {gauges:[{name:"foo", value:123, measure_time: @time},
                                  {name:"bar", value:456, measure_time: @time},
                                  {name:"baz", value:678, measure_time: @time}]}
            expect(q2.queued).to equal_unordered(expected)
          end

          it "merges counters" do
            q1 = Queue.new
            q1.add users: {type: :counter, value: 1000}
            q1.add sales: {type: :counter, value: 250}
            q2 = Queue.new
            q2.add signups: {type: :counter, value: 500}
            q2.merge!(q1)
            expected = {counters:[{name:"users", value:1000, measure_time: @time},
                                    {name:"sales", value:250, measure_time: @time},
                                    {name:"signups", value:500, measure_time: @time}]}
            expect(q2.queued).to equal_unordered(expected)
          end

          context "when multidimensional is true" do
            it "maintains specified tags" do
              q1 = Queue.new
              q1.add test: { tags: { db: "rr1" }, value: 123 }
              q2 = Queue.new(tags: { db: "rr2" })
              q2.merge!(q1)

              expect(q2.queued[:measurements].first[:tags][:db]).to eq("rr1")
            end

            it "does not change default tags" do
              q1 = Queue.new(tags: { db: "rr1" })
              q1.add test: 456
              q2 = Queue.new(tags: { db: "rr2" })
              q2.merge!(q1)

              expect(q2.queued[:tags][:db]).to eq("rr2")
            end

            it "tracks previous default tags" do
              q1 = Queue.new(tags: { db: "rr1" })
              q1.add test_1: 123
              q2 = Queue.new(tags: { db: "rr2" })
              q2.add test_2: 456
              q2.merge!(q1)
              metric = q2.measurements.find { |measurement| measurement[:name] == "test_1" }

              expect(metric[:tags][:db]).to eq("rr1")
            end
          end

          it "maintains specified sources" do
            q1 = Queue.new
            q1.add neo: {source: 'matrix', value: 123}
            q2 = Queue.new(source: 'red_pill')
            q2.merge!(q1)
            expect(q2.queued[:gauges][0][:source]).to eq('matrix')
          end

          it "does not change default source" do
            q1 = Queue.new(source: 'matrix')
            q1.add neo: 456
            q2 = Queue.new(source: 'red_pill')
            q2.merge!(q1)
            expect(q2.queued[:source]).to eq('red_pill')
          end

          it "tracks previous default source" do
            q1 = Queue.new(source: 'matrix')
            q1.add neo: 456
            q2 = Queue.new(source: 'red_pill')
            q2.add morpheus: 678
            q2.merge!(q1)
            q2.queued[:gauges].each do |gauge|
              if gauge[:name] == 'neo'
                expect(gauge[:source]).to eq('matrix')
              end
            end
          end
        end

          it "handles empty cases" do
            q1 = Queue.new
            q1.add foo: 123, users: {type: :counter, value: 1000}
            q2 = Queue.new
            q2.merge!(q1)
            expected = {counters: [{name:"users", value:1000, measure_time: @time}],
                        gauges: [{name:"foo", value:123, measure_time: @time}]}
            expect(q2.queued).to eq(expected)
          end

        context "with an aggregator" do
          it "merges" do
            aggregator = Aggregator.new(source: 'aggregator')
            aggregator.add timing: 102
            aggregator.add timing: 203
            queue = Queue.new(source: 'queue')
            queue.add gauge: 42
            queue.merge!(aggregator)
            expected = {gauges:[{name:"gauge", value:42, measure_time:@time},
                                  {name:"timing", count:2, sum:305.0, min:102.0, max:203.0, source:"aggregator"}],
                        source:'queue'}
            expect(queue.queued).to equal_unordered(expected)
          end
        end

        context "with a hash" do
          it "merges" do
            to_merge = {gauges:[{name: 'foo', value: 123}],
                        counters:[{name: 'bar', value: 456}]}
            q = Queue.new
            q.merge!(to_merge)
            expect(q.gauges.length).to eq(1)
            expect(q.counters.length).to eq(1)
          end
        end
      end

      describe "#per_request" do
        it "defaults to 500" do
          expect(subject.per_request).to eq(500)
        end
      end

      describe "#queued" do
        it "includes global source if set" do
          q = Queue.new(source: 'blah')
          q.add foo: 12
          expect(q.queued[:source]).to eq('blah')
        end

        it "includes global measure_time if set" do
          measure_time = (Time.now-1000).to_i
          q = Queue.new(measure_time: measure_time)
          q.add foo: 12
          expect(q.queued[:measure_time]).to eq(measure_time)
        end

        context "when tags are set" do
          it "includes global tags" do
            expected_tags = { region: "us-east-1" }
            queue = Queue.new(tags: expected_tags)
            queue.add test: 5
            expect(queue.queued[:tags]).to eq(expected_tags)
          end
        end

        context "when time is set" do
          it "includes global time" do
            expected_time = (Time.now-1000).to_i
            queue = Queue.new(time: expected_time)
            queue.add test: 10
            expect(queue.queued[:time]).to eq(expected_time)
          end
        end

      end

      describe "#size" do
        it "returns empty if gauges and counters are emtpy" do
          expect(subject.size).to be_zero
        end
        it "returns count of gauges and counters if added" do
          subject.add transactions: {type: :counter, value: 12345},
              register_cents: {type: :gauge, value: 211101}
          subject.add transactions: {type: :counter, value: 12345},
                      register_cents: {type: :gauge, value: 211101}
          expect(subject.size).to eq(4)
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
            expect(subject.queued).to be_empty
          end
        end

        context "when failed" do
          it "preserves queue and return false" do
            subject.add steps: 2042, distance: 1234
            subject.persister.return_value(false)
            expect(subject.submit).to be false
            expect(subject.queued).not_to be_empty
          end
        end
      end

      describe "#time" do
        context "with metric name only" do
          it "queues metric with timed value" do
            subject.time :sleeping do
              sleep 0.1
            end
            queued = subject.queued[:gauges][0]
            expect(queued[:name]).to eq('sleeping')
            expect(queued[:value]).to be >= 100
            expect(queued[:value]).to be_within(30).of(100)
          end
        end

        context "with metric and options" do
          it "queues metric with value and options" do
            subject.time :sleep_two, source: 'app1', period: 2 do
              sleep 0.05
            end
            queued = subject.queued[:gauges][0]
            expect(queued[:name]).to eq('sleep_two')
            expect(queued[:period]).to eq(2)
            expect(queued[:source]).to eq('app1')
            expect(queued[:value]).to be >= 50
            expect(queued[:value]).to be_within(30).of(50)
          end
        end
      end

    end # Queue

  end
end
