require 'spec_helper'

module Librato
  module Metrics

    describe Annotator do
      before(:all) { prep_integration_tests }
      before(:each) { delete_all_annotations }

      describe "#add" do
        it "should create new annotation" do
          subject.add :deployment, "deployed v68"
          annos = subject.fetch(:deployment, :start_time => Time.now.to_i-60)
          annos["events"]["unassigned"].length.should == 1
          annos["events"]["unassigned"][0]["title"].should == 'deployed v68'
        end
        it "should support sources" do
          subject.add :deployment, 'deployed v69', :source => 'box1'
          annos = subject.fetch(:deployment, :start_time => Time.now.to_i-60)
          annos["events"]["box1"].length.should == 1
          first = annos["events"]["box1"][0]
          first['title'].should == 'deployed v69'
        end
        it "should support start and end times" do
          start_time = Time.now.to_i-120
          end_time = Time.now.to_i-30
          subject.add :deployment, 'deployed v70', :start_time => start_time,
                      :end_time => end_time
          annos = subject.fetch(:deployment, :start_time => Time.now.to_i-180)
          annos["events"]["unassigned"].length.should == 1
          first = annos["events"]["unassigned"][0]
          first['title'].should == 'deployed v70'
          first['start_time'].should == start_time
          first['end_time'].should == end_time
        end
        it "should support description" do
          subject.add :deployment, 'deployed v71', :description => 'deployed foobar!'
          annos = subject.fetch(:deployment, :start_time => Time.now.to_i-180)
          annos["events"]["unassigned"].length.should == 1
          first = annos["events"]["unassigned"][0]
          first['title'].should == 'deployed v71'
          first['description'].should == 'deployed foobar!'
        end
        it "should have an id for further use" do
          annotation = subject.add :deployment, "deployed v23"
          annotation['id'].should_not be_nil
        end

        context "with a block" do
          it "should set both start and end times" do
            annotation = subject.add 'deploys', 'v345' do
              sleep 1.0
            end
            data = subject.fetch_event 'deploys', annotation['id']
            data['start_time'].should_not be_nil
            data['end_time'].should_not be_nil
          end
        end
      end

      describe "#delete" do
        it "should remove annotation streams" do
          subject.add :deployment, "deployed v45"
          subject.fetch :deployment # should exist
          subject.delete :deployment
          lambda {
            subject.fetch(:deployment)
          }.should raise_error(Metrics::NotFound)
        end
      end

      describe "#delete_event" do
        it "should remove an annotation event" do
          subject.add :deployment, 'deployed v46'
          subject.add :deployment, 'deployed v47'
          events = subject.fetch(:deployment, :start_time => Time.now.to_i-60)
          events = events['events']['unassigned']
          ids = events.reduce({}) do |hash, event|
            hash[event['title']] = event['id']
            hash
          end
          subject.delete_event :deployment, ids['deployed v47']
          events = subject.fetch(:deployment, :start_time => Time.now.to_i-60)
          events = events['events']['unassigned']
          events.length.should == 1
          events[0]['title'].should == 'deployed v46'
        end
      end

      describe "#fetch" do
        context "without a time frame" do
          it "should return stream properties" do
            subject.add :backups, "backup 21"
            properties = subject.fetch :backups
            properties['name'].should == 'backups'
          end
        end

        context "with a time frame" do
          it "should return set of annotations" do
            subject.add :backups, "backup 22"
            subject.add :backups, "backup 23"
            annos = subject.fetch :backups, :start_time => Time.now.to_i-60
            events = annos['events']['unassigned']
            events[0]['title'].should == 'backup 22'
            events[1]['title'].should == 'backup 23'
          end
          it "should respect source limits" do
            subject.add :backups, "backup 24", :source => 'server_1'
            subject.add :backups, "backup 25", :source => 'server_2'
            subject.add :backups, "backup 26", :source => 'server_3'
            annos = subject.fetch :backups, :start_time => Time.now.to_i-60,
                                  :sources => %w{server_1 server_3}
            annos['events']['server_1'].should_not be_nil
            annos['events']['server_2'].should be_nil
            annos['events']['server_3'].should_not be_nil
          end
        end

        it "should return exception if annotation is missing" do
          lambda {
            subject.fetch :backups
          }.should raise_error(Metrics::NotFound)
        end
      end

      describe "#fetch_event" do
        context "with existing event" do
          it "should return event properties" do
            annotation = subject.add 'deploys', 'v69'
            data = subject.fetch_event 'deploys', annotation['id']
            data['title'].should == 'v69'
          end
        end
        context "when event doesn't exist" do
          it "should raise NotFound" do
            lambda {
              data = subject.fetch_event 'deploys', 324
            }.should raise_error(Metrics::NotFound)
          end
        end
      end

      describe "#list" do
        before(:each) do
          subject.add :backups, 'backup 1'
          subject.add :deployment, 'deployed v74'
        end

        context "without arguments" do
          it "should list annotation streams" do
            streams = subject.list
            streams['annotations'].length.should == 2
            streams = streams['annotations'].map{|i| i['name']}
            streams.should include('backups')
            streams.should include('deployment')
          end
        end
        context "with an argument" do
          it "should list annotation streams which match" do
            streams = subject.list :name => 'back'
            streams['annotations'].length.should == 1
            streams = streams['annotations'].map{|i| i['name']}
            streams.should include('backups')
          end
        end
      end

      describe "#update_event" do
        context "when event exists" do
          it "should update event" do
            end_time = (Time.now + 60).to_i
            annotation = subject.add 'deploys', 'v24'
            subject.update_event 'deploys', annotation['id'],
              :end_time => end_time, :title => 'v28'
            data = subject.fetch_event 'deploys', annotation['id']

            data['title'].should == 'v28'
            data['end_time'].should == end_time
          end
        end
        context "when event does not exist" do

        end
      end

    end

  end
end
