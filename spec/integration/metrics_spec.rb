require 'spec_helper'

module Librato
  describe Metrics do
    before(:all) { prep_integration_tests }

    describe "#annotate" do
      before(:all) { @annotator = Metrics::Annotator.new }
      before(:each) { delete_all_annotations }

      it "should create new annotation" do
        Metrics.annotate :deployment, "deployed v68"
        annos = @annotator.fetch(:deployment, :start_time => Time.now.to_i-60)
        annos["events"]["unassigned"].length.should == 1
        annos["events"]["unassigned"][0]["title"].should == 'deployed v68'
      end
      it "should support sources" do
        Metrics.annotate :deployment, 'deployed v69', :source => 'box1'
        annos = @annotator.fetch(:deployment, :start_time => Time.now.to_i-60)
        annos["events"]["box1"].length.should == 1
        first = annos["events"]["box1"][0]
        first['title'].should == 'deployed v69'
      end
      it "should support start and end times" do
        start_time = Time.now.to_i-120
        end_time = Time.now.to_i-30
        Metrics.annotate :deployment, 'deployed v70', :start_time => start_time,
                    :end_time => end_time
        annos = @annotator.fetch(:deployment, :start_time => Time.now.to_i-180)
        annos["events"]["unassigned"].length.should == 1
        first = annos["events"]["unassigned"][0]
        first['title'].should == 'deployed v70'
        first['start_time'].should == start_time
        first['end_time'].should == end_time
      end
      it "should support description" do
        Metrics.annotate :deployment, 'deployed v71', :description => 'deployed foobar!'
        annos = @annotator.fetch(:deployment, :start_time => Time.now.to_i-180)
        annos["events"]["unassigned"].length.should == 1
        first = annos["events"]["unassigned"][0]
        first['title'].should == 'deployed v71'
        first['description'].should == 'deployed foobar!'
      end
    end

    describe "#delete_metrics" do
      before(:each) { delete_all_metrics }

      context 'by names' do

        context "with a single argument" do
          it "should delete named metric" do
            Metrics.submit :foo => 123
            Metrics.metrics(:name => :foo).should_not be_empty
            Metrics.delete_metrics :foo
            Metrics.metrics(:name => :foo).should be_empty
          end
        end

        context "with multiple arguments" do
          it "should delete named metrics" do
            Metrics.submit :foo => 123, :bar => 345, :baz => 567
            Metrics.delete_metrics :foo, :bar
            Metrics.metrics(:name => :foo).should be_empty
            Metrics.metrics(:name => :bar).should be_empty
            Metrics.metrics(:name => :baz).should_not be_empty
          end
        end

        context "with missing metric" do
          it "should run cleanly" do
            # the API currently returns success even if
            # the metric has already been deleted or is absent.
            Metrics.delete_metrics :missing
          end
        end

        context "with no arguments" do
          it "should not make request" do
            lambda {
              Metrics.delete_metrics
            }.should raise_error(Metrics::NoMetricsProvided)
          end
        end

      end

      context 'by pattern' do
        it "should filter properly" do
          Metrics.submit :foo => 1, :foobar => 2, :foobaz => 3, :bar => 4
          Metrics.delete_metrics :names => 'fo*', :exclude => ['foobar']

          %w{foo foobaz}.each do |name|
            lambda {
              Metrics.get_metric name
            }.should raise_error(Librato::Metrics::NotFound)
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
        it "should get metric attributes" do
          metric = Metrics.get_metric :my_counter
          metric['name'].should == 'my_counter'
          metric['type'].should == 'counter'
        end
      end

      context "with a start_time" do
        it "should return entries since that time" do
          # 1 hr ago
          metric = Metrics.get_metric :my_counter, :start_time => Time.now-3600
          data = metric['measurements']
          data['unassigned'].length.should == 3
          data['baz'].length.should == 2
        end
      end

      context "with a count limit" do
        it "should return that number of entries per source" do
          metric = Metrics.get_metric :my_counter, :count => 2
          data = metric['measurements']
          data['unassigned'].length.should == 2
          data['baz'].length.should == 2
        end
      end

      context "with a source limit" do
        it "should only return that source" do
          metric = Metrics.get_metric :my_counter, :source => 'baz', :start_time => Time.now-3600
          data = metric['measurements']
          data['baz'].length.should == 2
          data['unassigned'].should be_nil
        end
      end

    end

    describe "#metrics" do
      before(:all) do
        delete_all_metrics
        Metrics.submit :foo => 123, :bar => 345, :baz => 678, :foo_2 => 901
      end

      context "without arguments" do
        it "should list all metrics" do
          metric_names = Metrics.metrics.map { |metric| metric['name'] }
          metric_names.sort.should == %w{foo bar baz foo_2}.sort
        end
      end

      context "with a name argument" do
        it "should list metrics that match" do
          metric_names = Metrics.metrics(:name => 'foo').map { |metric| metric['name'] }
          metric_names.sort.should == %w{foo foo_2}.sort
        end
      end

    end

    describe "#submit" do

      context "with a gauge" do
        before(:all) do
          delete_all_metrics
          Metrics.submit :foo => 123
        end

        it "should create the metrics" do
          metric = Metrics.metrics[0]
          metric['name'].should == 'foo'
          metric['type'].should == 'gauge'
        end

        it "should store their data" do
          data = Metrics.get_measurements :foo, :count => 1
          data.should_not be_empty
          data['unassigned'][0]['value'] == 123.0
        end
      end

      context "with a counter" do
        before(:all) do
          delete_all_metrics
          Metrics.submit :bar => {:type => :counter, :source => 'baz', :value => 456}
        end

        it "should create the metrics" do
          metric = Metrics.metrics[0]
          metric['name'].should == 'bar'
          metric['type'].should == 'counter'
        end

        it "should store their data" do
          data = Metrics.get_measurements :bar, :count => 1
          data.should_not be_empty
          data['baz'][0]['value'] == 456.0
        end
      end

      it "should not retain errors" do
        delete_all_metrics
        Metrics.submit :foo => {:type => :counter, :value => 12}
        lambda {
          Metrics.submit :foo => 15 # submitting as gauge
        }.should raise_error
        lambda {
          Metrics.submit :foo => {:type => :counter, :value => 17}
        }.should_not raise_error
      end

    end

    describe "#update_metric[s]" do

      context 'with a single metric' do
        context "with an existing metric" do
          before do
            delete_all_metrics
            Metrics.submit :foo => 123
          end

          it "should update the metric" do
            Metrics.update_metric :foo, :display_name => "Foo Metric",
                                        :period => 15,
                                        :attributes => {
                                          :display_max => 1000
                                        }
            foo = Metrics.get_metric :foo
            foo['display_name'].should == 'Foo Metric'
            foo['period'].should == 15
            foo['attributes']['display_max'].should == 1000
          end
        end

        context "without an existing metric" do
          it "should create the metric if type specified" do
            delete_all_metrics
            Metrics.update_metric :foo, :display_name => "Foo Metric",
                                        :type => 'gauge',
                                        :period => 15,
                                        :attributes => {
                                        :display_max => 1000
                                      }
            foo = Metrics.get_metric :foo
            foo['display_name'].should == 'Foo Metric'
            foo['period'].should == 15
            foo['attributes']['display_max'].should == 1000
          end

          it "should raise error if no type specified" do
            delete_all_metrics
            lambda {
              Metrics.update_metric :foo, :display_name => "Foo Metric",
                                          :period => 15,
                                          :attributes => {
                                            :display_max => 1000
                                          }
            }.should raise_error
          end
        end

      end

      context 'with multiple metrics' do
        before do
          delete_all_metrics
          Metrics.submit 'my.1' => 1, 'my.2' => 2, 'my.3' => 3, 'my.4' => 4
        end

        it "should support named list" do
          names = ['my.1', 'my.3']
          Metrics.update_metrics :names => names, :period => 60

          names.each do |name|
             metric = Metrics.get_metric name
             metric['period'].should == 60
           end
        end

        it "should support patterns" do
          Metrics.update_metrics :names => 'my.*', :exclude => ['my.3'],
            :display_max => 100

          %w{my.1 my.2 my.4}.each do |name|
            metric = Metrics.get_metric name
            metric['attributes']['display_max'].should == 100
          end

          excluded = Metrics.get_metric 'my.3'
          excluded['attributes']['display_max'].should_not == 100
        end
      end
    end

    describe "Sources API" do
      before do
        Metrics.update_source("sources_api_test", display_name: "Sources Api Test")
      end

      describe "#sources" do
        it "should work" do
          sources = Metrics.sources
          sources.should be_an(Array)
          test_source = sources.detect { |s| s["name"] == "sources_api_test" }
          test_source["display_name"].should == "Sources Api Test"
        end

        it "should allow filtering by name" do
          sources = Metrics.sources name: 'sources_api_test'
          sources.all? {|s| s['name'] =~ /sources_api_test/}.should be_true
        end
      end

      describe "#get_source" do
        it "should work" do
          test_source = Metrics.get_source("sources_api_test")
          test_source["display_name"].should == "Sources Api Test"
        end
      end

      describe "#update_source" do
        it "should update an existing source" do
          Metrics.update_source("sources_api_test", display_name: "Updated Source Name")

          test_source = Metrics.get_source("sources_api_test")
          test_source["display_name"].should == "Updated Source Name"
        end

        it "should create new sources" do
          source_name = "sources_api_test_#{Time.now.to_f}"
          lambda {
            no_source = Metrics.get_source(source_name)
          }.should raise_error(Librato::Metrics::NotFound)

          Metrics.update_source(source_name, display_name: "New Source")

          test_source = Metrics.get_source(source_name)
          test_source.should_not be_nil
          test_source["display_name"].should == "New Source"
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
