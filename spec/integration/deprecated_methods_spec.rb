require 'spec_helper'

DEPRECATED_METHODS = %w[fetch list update delete]
describe Librato::Metrics do

  DEPRECATED_METHODS.each do |deprecated_method|
    it { is_expected.to respond_to(deprecated_method) }
  end

  describe "Client" do
    let(:client) { Librato::Metrics.client }
    subject { client }

    before(:all) { prep_integration_tests }

    before do
      client.submit :test_metric => 123.0
    end

    DEPRECATED_METHODS.each do |deprecated_method|
      it { is_expected.to respond_to(deprecated_method) }
    end

    describe "#fetch" do
      context "with no measurements attributes" do
        let(:metric) { client.fetch(:test_metric) }
        subject { metric }

        it { is_expected.not_to be_nil }

        it "returns a metric" do
          expect(metric["name"]).to eq("test_metric")
        end
      end

      context "with measurements attributes" do
        let(:measurements) { client.fetch(:test_metric, :count => 1) }
        subject { measurements }

        it { is_expected.not_to be_nil }
        it { is_expected.not_to be_empty }

        it "returns the measurements" do
          expect(measurements).to have_key("unassigned")
          expect(measurements["unassigned"]).to be_an(Array)
          expect(measurements["unassigned"].first["value"]).to eq(123.0)
        end
      end
    end

    describe "#list" do
      let(:metrics) { client.list }
      subject { metrics }

      it { is_expected.not_to be_nil }
      it { is_expected.not_to be_empty }

      it "returns the list of metrics" do
        metric = metrics.find { |m| m["name"] == "test_metric" }
        expect(metric).not_to be_nil
      end
    end

    describe "#update" do
      before do
        client.update("test_metric", :display_name => "Test Deprecated Update")
      end

      let(:updated_metric) { client.get_metric("test_metric") }

      it "updates the metric" do
        expect(updated_metric["display_name"]).to eq("Test Deprecated Update")
      end
    end

    describe "#delete" do
      it "deletes the metric" do
        expect(client.metrics(:name => "test_metric")).not_to be_empty
        client.delete("test_metric")
        expect(client.metrics(:name => "test_metric")).to be_empty
      end
    end

  end
end
