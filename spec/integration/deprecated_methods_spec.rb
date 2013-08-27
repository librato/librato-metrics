require 'spec_helper'

DEPRECATED_METHODS = %w[fetch list update delete]
describe Librato::Metrics do

  DEPRECATED_METHODS.each do |deprecated_method|
    it { should respond_to(deprecated_method) }
  end

  describe "Client" do
    let(:client) { Librato::Metrics.client }
    subject { client }

    before(:all) { prep_integration_tests }

    before do
      client.submit :test_metric => 123.0
    end

    DEPRECATED_METHODS.each do |deprecated_method|
      it { should respond_to(deprecated_method) }
    end

    describe "#fetch" do
      context "with no measurements attributes" do
        let(:metric) { client.fetch(:test_metric) }
        subject { metric }

        it { should_not be_nil }

        it "should return a metric" do
          metric["name"].should == "test_metric"
        end
      end

      context "with measurements attributes" do
        let(:measurements) { client.fetch(:test_metric, :count => 1) }
        subject { measurements }

        it { should_not be_nil }
        it { should_not be_empty }

        it "should return the measurements" do
          measurements.should have_key("unassigned")
          measurements["unassigned"].should be_an(Array)
          measurements["unassigned"].first["value"].should == 123.0
        end
      end
    end

    describe "#list" do
      let(:metrics) { client.list }
      subject { metrics }

      it { should_not be_nil }
      it { should_not be_empty }

      it "should return the list of metrics" do
        metric = metrics.find { |m| m["name"] == "test_metric" }
        metric.should_not be_nil
      end
    end

    describe "#update" do
      before do
        client.update("test_metric", :display_name => "Test Deprecated Update")
      end

      let(:updated_metric) { client.get_metric("test_metric") }

      it "should update the metric" do
        updated_metric["display_name"].should == "Test Deprecated Update"
      end
    end

    describe "#delete" do
      it "should delete the metric" do
        client.metrics(:name => "test_metric").should_not be_empty
        client.delete("test_metric")
        client.metrics(:name => "test_metric").should be_empty
      end
    end

  end
end
