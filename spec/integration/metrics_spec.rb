require 'spec_helper'

module Librato
  describe Metrics do
    before(:all) { prep_integration_tests }

    describe "#annotate" do
      before(:all) { @annotator = Metrics::Annotator.new }
      before(:each) { delete_all_annotations }

      it "creates new annotation" do
        Metrics.annotate :deployment, "deployed v68"
        annos = @annotator.fetch(:deployment, :start_time => Time.now.to_i-60)
        expect(annos["events"]["unassigned"].length).to eq(1)
        expect(annos["events"]["unassigned"][0]["title"]).to eq('deployed v68')
      end
      it "supports sources" do
        Metrics.annotate :deployment, 'deployed v69', :source => 'box1'
        annos = @annotator.fetch(:deployment, :start_time => Time.now.to_i-60)
        expect(annos["events"]["box1"].length).to eq(1)
        first = annos["events"]["box1"][0]
        expect(first['title']).to eq('deployed v69')
      end
      it "supports start and end times" do
        start_time = Time.now.to_i-120
        end_time = Time.now.to_i-30
        Metrics.annotate :deployment, 'deployed v70', :start_time => start_time,
                    :end_time => end_time
        annos = @annotator.fetch(:deployment, :start_time => Time.now.to_i-180)
        expect(annos["events"]["unassigned"].length).to eq(1)
        first = annos["events"]["unassigned"][0]
        expect(first['title']).to eq('deployed v70')
        expect(first['start_time']).to eq(start_time)
        expect(first['end_time']).to eq(end_time)
      end
      it "supports description" do
        Metrics.annotate :deployment, 'deployed v71', :description => 'deployed foobar!'
        annos = @annotator.fetch(:deployment, :start_time => Time.now.to_i-180)
        expect(annos["events"]["unassigned"].length).to eq(1)
        first = annos["events"]["unassigned"][0]
        expect(first['title']).to eq('deployed v71')
        expect(first['description']).to eq('deployed foobar!')
      end
    end

    describe "#delete_metrics" do
      before(:each) { delete_all_metrics }

      context 'with names' do

        context "with a single argument" do
          it "deletes named metric" do
            Metrics.submit :foo => 123
            expect(Metrics.metrics(:name => :foo)).not_to be_empty
            Metrics.delete_metrics :foo
            expect(Metrics.metrics(:name => :foo)).to be_empty
          end
        end

        context "with multiple arguments" do
          it "deletes named metrics" do
            Metrics.submit :foo => 123, :bar => 345, :baz => 567
            Metrics.delete_metrics :foo, :bar
            expect(Metrics.metrics(:name => :foo)).to be_empty
            expect(Metrics.metrics(:name => :bar)).to be_empty
            expect(Metrics.metrics(:name => :baz)).not_to be_empty
          end
        end

        context "with missing metric" do
          it "runs cleanly" do
            # the API currently returns success even if
            # the metric has already been deleted or is absent.
            Metrics.delete_metrics :missing
          end
        end

        context "with no arguments" do
          it "does not make request" do
            expect {
              Metrics.delete_metrics
            }.to raise_error(Metrics::NoMetricsProvided)
          end
        end

      end

      context 'with patterns' do
        it "filters properly" do
          Metrics.submit :foo => 1, :foobar => 2, :foobaz => 3, :bar => 4
          Metrics.delete_metrics :names => 'fo*', :exclude => ['foobar']

          %w{foo foobaz}.each do |name|
            expect {
              Metrics.get_metric name
            }.to raise_error(Librato::Metrics::NotFound)
          end

          %w{foobar bar}.each do |name|
            Metrics.get_metric name # stil exist
          end
        end
      end
    end

    describe "#get_metric" do
      before(:all) do
        delete_all_metrics
        Metrics.submit :my_counter => {:type => :counter, :value => 0, :measure_time => Time.now.to_i-60}
        1.upto(2).each do |i|
          measure_time = Time.now.to_i - (5+i)
          opts = {:measure_time => measure_time, :type => :counter}
          Metrics.submit :my_counter => opts.merge(:value => i)
          Metrics.submit :my_counter => opts.merge(:source => 'baz', :value => i+1)
        end
      end

      context "without arguments" do
        it "gets metric attributes" do
          metric = Metrics.get_metric :my_counter
          expect(metric['name']).to eq('my_counter')
          expect(metric['type']).to eq('counter')
        end
      end

      context "with a start_time" do
        it "returns entries since that time" do
          # 1 hr ago
          metric = Metrics.get_metric :my_counter, :start_time => Time.now-3600
          data = metric['measurements']
          expect(data['unassigned'].length).to eq(3)
          expect(data['baz'].length).to eq(2)
        end
      end

      context "with a count limit" do
        it "returns that number of entries per source" do
          metric = Metrics.get_metric :my_counter, :count => 2
          data = metric['measurements']
          expect(data['unassigned'].length).to eq(2)
          expect(data['baz'].length).to eq(2)
        end
      end

      context "with a source limit" do
        it "only returns that source" do
          metric = Metrics.get_metric :my_counter, :source => 'baz', :start_time => Time.now-3600
          data = metric['measurements']
          expect(data['baz'].length).to eq(2)
          expect(data['unassigned']).to be_nil
        end
      end

    end

    describe "#metrics" do
      before(:all) do
        delete_all_metrics
        Metrics.submit :foo => 123, :bar => 345, :baz => 678, :foo_2 => 901
      end

      context "without arguments" do
        it "lists all metrics" do
          metric_names = Metrics.metrics.map { |metric| metric['name'] }
          expect(metric_names.sort).to eq(%w{foo bar baz foo_2}.sort)
        end
      end

      context "with a name argument" do
        it "lists metrics that match" do
          metric_names = Metrics.metrics(:name => 'foo').map { |metric| metric['name'] }
          expect(metric_names.sort).to eq(%w{foo foo_2}.sort)
        end
      end

    end

    describe "#submit" do

      context "with a gauge" do
        before(:all) do
          delete_all_metrics
          Metrics.submit :foo => 123
        end

        it "creates the metrics" do
          metric = Metrics.metrics[0]
          expect(metric['name']).to eq('foo')
          expect(metric['type']).to eq('gauge')
        end

        it "stores their data" do
          data = Metrics.get_measurements :foo, :count => 1
          expect(data).not_to be_empty
          data['unassigned'][0]['value'] == 123.0
        end
      end

      context "with a counter" do
        before(:all) do
          delete_all_metrics
          Metrics.submit :bar => {:type => :counter, :source => 'baz', :value => 456}
        end

        it "creates the metrics" do
          metric = Metrics.metrics[0]
          expect(metric['name']).to eq('bar')
          expect(metric['type']).to eq('counter')
        end

        it "stores their data" do
          data = Metrics.get_measurements :bar, :count => 1
          expect(data).not_to be_empty
          data['baz'][0]['value'] == 456.0
        end
      end

      it "does not retain errors" do
        delete_all_metrics
        Metrics.submit :foo => {:type => :counter, :value => 12}
        expect {
          Metrics.submit :foo => 15 # submitting as gauge
        }.to raise_error
        expect {
          Metrics.submit :foo => {:type => :counter, :value => 17}
        }.not_to raise_error
      end

    end

    describe "#update_metric[s]" do

      context 'with a single metric' do
        context "with an existing metric" do
          before do
            delete_all_metrics
            Metrics.submit :foo => 123
          end

          it "updates the metric" do
            Metrics.update_metric :foo, :display_name => "Foo Metric",
                                        :period => 15,
                                        :attributes => {
                                          :display_max => 1000
                                        }
            foo = Metrics.get_metric :foo
            expect(foo['display_name']).to eq('Foo Metric')
            expect(foo['period']).to eq(15)
            expect(foo['attributes']['display_max']).to eq(1000)
          end
        end

        context "without an existing metric" do
          it "creates the metric if type specified" do
            delete_all_metrics
            Metrics.update_metric :foo, :display_name => "Foo Metric",
                                        :type => 'gauge',
                                        :period => 15,
                                        :attributes => {
                                        :display_max => 1000
                                      }
            foo = Metrics.get_metric :foo
            expect(foo['display_name']).to eq('Foo Metric')
            expect(foo['period']).to eq(15)
            expect(foo['attributes']['display_max']).to eq(1000)
          end

          it "raises error if no type specified" do
            delete_all_metrics
            expect {
              Metrics.update_metric :foo, :display_name => "Foo Metric",
                                          :period => 15,
                                          :attributes => {
                                            :display_max => 1000
                                          }
            }.to raise_error
          end
        end

      end

      context 'with multiple metrics' do
        before do
          delete_all_metrics
          Metrics.submit 'my.1' => 1, 'my.2' => 2, 'my.3' => 3, 'my.4' => 4
        end

        it "supports named list" do
          names = ['my.1', 'my.3']
          Metrics.update_metrics :names => names, :period => 60

          names.each do |name|
             metric = Metrics.get_metric name
             expect(metric['period']).to eq(60)
           end
        end

        it "supports patterns" do
          Metrics.update_metrics :names => 'my.*', :exclude => ['my.3'],
            :display_max => 100

          %w{my.1 my.2 my.4}.each do |name|
            metric = Metrics.get_metric name
            expect(metric['attributes']['display_max']).to eq(100)
          end

          excluded = Metrics.get_metric 'my.3'
          expect(excluded['attributes']['display_max']).not_to eq(100)
        end
      end
    end

    describe "Sources API" do
      before do
        Metrics.update_source("sources_api_test", display_name: "Sources Api Test")
      end

      describe "#sources" do
        it "works" do
          sources = Metrics.sources
          expect(sources).to be_an(Array)
          test_source = sources.detect { |s| s["name"] == "sources_api_test" }
          expect(test_source["display_name"]).to eq("Sources Api Test")
        end

        it "allows filtering by name" do
          sources = Metrics.sources name: 'sources_api_test'
          expect(sources.all? {|s| s['name'] =~ /sources_api_test/}).to be_truthy
        end
      end

      describe "#get_source" do
        it "works" do
          test_source = Metrics.get_source("sources_api_test")
          expect(test_source["display_name"]).to eq("Sources Api Test")
        end
      end

      describe "#update_source" do
        it "updates an existing source" do
          Metrics.update_source("sources_api_test", display_name: "Updated Source Name")

          test_source = Metrics.get_source("sources_api_test")
          expect(test_source["display_name"]).to eq("Updated Source Name")
        end

        it "creates new sources" do
          source_name = "sources_api_test_#{Time.now.to_f}"
          expect {
            no_source = Metrics.get_source(source_name)
          }.to raise_error(Librato::Metrics::NotFound)

          Metrics.update_source(source_name, display_name: "New Source")

          test_source = Metrics.get_source(source_name)
          expect(test_source).not_to be_nil
          expect(test_source["display_name"]).to eq("New Source")
        end
      end

    end

    # Note: These are challenging to test end-to-end, should probably
    # unit test instead. Disabling for now.
    #
    # describe "Snapshots API" do
    #
    #   let(:instrument_id) do
    #     instrument_options = {name: "Snapshot test subject"}
    #     conn = Metrics.connection
    #     resp = conn.post do |req|
    #       req.url conn.build_url("/v1/instruments")
    #       req.body = Librato::Metrics::SmartJSON.write(instrument_options)
    #     end
    #     instrument_id = Librato::Metrics::SmartJSON.read(resp.body)["id"]
    #   end
    #
    #   let(:subject) do
    #     {instrument: {href: "http://api.librato.dev/v1/instruments/#{instrument_id}"}}
    #   end
    #
    #   it "should #create_snapshot" do
    #     result = Metrics.create_snapshot(subject: subject)
    #     result["href"].should =~ /snapshots\/\d+$/
    #   end
    #
    #   it "should #get_snapshot" do
    #     result = Metrics.create_snapshot(subject: subject)
    #     snapshot_id = result["href"][/(\d+)$/]
    #
    #     result = Metrics.get_snapshot(snapshot_id)
    #     result["href"].should =~ /snapshots\/\d+$/
    #   end
    # end

  end
end
