require 'spec_helper'

module Librato
  module Metrics

    describe Queue do
      before(:all) { prep_integration_tests }
      before(:each) do
        delete_all_metrics
        Librato::Metrics.client.clear_tags
      end

      context "with a large number of metrics" do
        it "submits them in multiple requests" do
          Middleware::CountRequests.reset
          queue = Queue.new(per_request: 3)
          (1..10).each do |i|
            queue.add "gauge_#{i}" => 1
          end
          queue.submit
          expect(Middleware::CountRequests.total_requests).to eq(4)
        end

        it "persists all metrics" do
          queue = Queue.new(per_request: 2)
          (1..5).each do |i|
            queue.add "gauge_#{i}" => i
          end
          (1..3).each do |i|
            queue.add "counter_#{i}" => {type: :counter, value: i}
          end
          queue.submit

          metrics = Metrics.metrics
          expect(metrics.length).to eq(8)
          counter = Metrics.get_measurements :counter_3, count: 1
          expect(counter['unassigned'][0]['value']).to eq(3)
          gauge = Metrics.get_measurements :gauge_5, count: 1
          expect(gauge['unassigned'][0]['value']).to eq(5)
        end

        it "applies globals to each request" do
          source = 'yogi'
          measure_time = Time.now.to_i-3
          queue = Queue.new(
            per_request: 3,
            source: source,
            measure_time: measure_time,
            skip_measurement_times: true
          )
          (1..5).each do |i|
            queue.add "gauge_#{i}" => 1
          end
          queue.submit

          # verify globals have persisted for all requests
          gauge = Metrics.get_measurements :gauge_5, count: 1
          expect(gauge[source][0]["value"]).to eq(1.0)
          expect(gauge[source][0]["measure_time"]).to eq(measure_time)
        end
      end

      it "respects default and individual sources" do
        queue = Queue.new(source: 'default')
        queue.add foo: 123
        queue.add bar: {value: 456, source: 'barsource'}
        queue.submit

        foo = Metrics.get_measurements :foo, count: 2
        expect(foo['default'][0]['value']).to eq(123)

        bar = Metrics.get_measurements :bar, count: 2
        expect(bar['barsource'][0]['value']).to eq(456)
      end

      context "with tags" do
        let(:queue) { Queue.new(tags: { a: "b" } ) }

        it "respects default and individual tags" do
          queue.add test_1: 123
          queue.add test_2: { value: 456, tags: { c: "d" }}
          queue.submit

          test_1 = Librato::Metrics.get_measurement :test_1, resolution: 1, duration: 3600
          expect(test_1["series"][0]["tags"]["a"]).to eq("b")
          expect(test_1["series"][0]["measurements"][0]["value"]).to eq(123)

          test_2 = Metrics.get_measurement :test_2, resolution: 1, duration: 3600
          expect(test_2["series"][0]["tags"]["c"]).to eq("d")
          expect(test_2["series"][0]["measurements"][0]["value"]).to eq(456)
        end
      end

    end

  end
end
