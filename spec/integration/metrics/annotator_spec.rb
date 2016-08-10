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
          expect(annos["events"]["unassigned"].length).to eq(1)
          expect(annos["events"]["unassigned"][0]["title"]).to eq('deployed v68')
        end
        it "should support sources" do
          subject.add :deployment, 'deployed v69', :source => 'box1'
          annos = subject.fetch(:deployment, :start_time => Time.now.to_i-60)
          expect(annos["events"]["box1"].length).to eq(1)
          first = annos["events"]["box1"][0]
          expect(first['title']).to eq('deployed v69')
        end
        it "should support start and end times" do
          start_time = Time.now.to_i-120
          end_time = Time.now.to_i-30
          subject.add :deployment, 'deployed v70', :start_time => start_time,
                      :end_time => end_time
          annos = subject.fetch(:deployment, :start_time => Time.now.to_i-180)
          expect(annos["events"]["unassigned"].length).to eq(1)
          first = annos["events"]["unassigned"][0]
          expect(first['title']).to eq('deployed v70')
          expect(first['start_time']).to eq(start_time)
          expect(first['end_time']).to eq(end_time)
        end
        it "should support description" do
          subject.add :deployment, 'deployed v71', :description => 'deployed foobar!'
          annos = subject.fetch(:deployment, :start_time => Time.now.to_i-180)
          expect(annos["events"]["unassigned"].length).to eq(1)
          first = annos["events"]["unassigned"][0]
          expect(first['title']).to eq('deployed v71')
          expect(first['description']).to eq('deployed foobar!')
        end
        it "should have an id for further use" do
          annotation = subject.add :deployment, "deployed v23"
          expect(annotation['id']).not_to be_nil
        end

        context "with a block" do
          it "should set both start and end times" do
            annotation = subject.add 'deploys', 'v345' do
              sleep 1.0
            end
            data = subject.fetch_event 'deploys', annotation['id']
            expect(data['start_time']).not_to be_nil
            expect(data['end_time']).not_to be_nil
          end
        end
      end

      describe "#delete" do
        it "should remove annotation streams" do
          subject.add :deployment, "deployed v45"
          subject.fetch :deployment # should exist
          subject.delete :deployment
          expect {
            subject.fetch(:deployment)
          }.to raise_error(Metrics::NotFound)
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
          expect(events.length).to eq(1)
          expect(events[0]['title']).to eq('deployed v46')
        end
      end

      describe "#fetch" do
        context "without a time frame" do
          it "should return stream properties" do
            subject.add :backups, "backup 21"
            properties = subject.fetch :backups
            expect(properties['name']).to eq('backups')
          end
        end

        context "with a time frame" do
          it "should return set of annotations" do
            subject.add :backups, "backup 22"
            subject.add :backups, "backup 23"
            annos = subject.fetch :backups, :start_time => Time.now.to_i-60
            events = annos['events']['unassigned']
            expect(events[0]['title']).to eq('backup 22')
            expect(events[1]['title']).to eq('backup 23')
          end
          it "should respect source limits" do
            subject.add :backups, "backup 24", :source => 'server_1'
            subject.add :backups, "backup 25", :source => 'server_2'
            subject.add :backups, "backup 26", :source => 'server_3'
            annos = subject.fetch :backups, :start_time => Time.now.to_i-60,
                                  :sources => %w{server_1 server_3}
            expect(annos['events']['server_1']).not_to be_nil
            expect(annos['events']['server_2']).to be_nil
            expect(annos['events']['server_3']).not_to be_nil
          end
        end

        it "should return exception if annotation is missing" do
          expect {
            subject.fetch :backups
          }.to raise_error(Metrics::NotFound)
        end
      end

      describe "#fetch_event" do
        context "with existing event" do
          it "should return event properties" do
            annotation = subject.add 'deploys', 'v69'
            data = subject.fetch_event 'deploys', annotation['id']
            expect(data['title']).to eq('v69')
          end
        end
        context "when event doesn't exist" do
          it "should raise NotFound" do
            expect {
              data = subject.fetch_event 'deploys', 324
            }.to raise_error(Metrics::NotFound)
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
            expect(streams['annotations'].length).to eq(2)
            streams = streams['annotations'].map{|i| i['name']}
            expect(streams).to include('backups')
            expect(streams).to include('deployment')
          end
        end
        context "with an argument" do
          it "should list annotation streams which match" do
            streams = subject.list :name => 'back'
            expect(streams['annotations'].length).to eq(1)
            streams = streams['annotations'].map{|i| i['name']}
            expect(streams).to include('backups')
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

            expect(data['title']).to eq('v28')
            expect(data['end_time']).to eq(end_time)
          end
        end
        context "when event does not exist" do

        end
      end

    end

  end
end
