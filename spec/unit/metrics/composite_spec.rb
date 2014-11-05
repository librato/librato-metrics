require 'spec_helper'

module Librato
  module Metrics

    describe Composite do

      it {should respond_to :client}
      it {should respond_to :compose}
      it {should respond_to :resolution}
      it {should respond_to :start_time}
      it {should respond_to :end_time}

      describe "#client" do
        it "defaults to Librato::Metrics client" do
          subject.client.should eql Librato::Metrics.client
        end

        it "can be set on initialize" do
          c = double('client')
          Composite.new(client: c).client.should eql c
        end
      end

      describe "#initialize" do
        let(:compose) {'s("my.metric", "*")'}
        let(:resolution) {60}
        let(:end_time) {Time.now.to_i}
        let(:start_time) {end_time - 3600}

        subject do
          Composite.new(
            compose: compose,
            resolution: resolution,
            start_time: start_time,
            end_time: end_time
          )
        end

        its(:compose) {should eql compose}
        its(:resolution) {should eql resolution}
        its(:start_time) {should eql start_time}
        its(:end_time) {should eql end_time}
      end

      describe "#composite_params" do
        subject do
          Composite.new(
            compose: 's("met", "*")',
            resolution: 60,
            start_time: 1234,
            end_time: 5678
          )
        end

        it "contains all the appropriate composite parameters" do
          subject.composite_params.should eql(
            {
              compose: subject.compose,
              resolution: subject.resolution,
              start_time: subject.start_time,
              end_time: subject.end_time
            }
          )
        end
      end

    end

  end
end
