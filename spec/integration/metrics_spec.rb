require 'spec_helper'

module Librato
  describe Metrics do
    before(:all) { prep_integration_tests }

    describe "#list" do

      before(:all) do
        delete_all_metrics
        Librato::Metrics.submit :foo => 123, :bar => 345, :baz => 678, :foo_2 => 901
      end

      context "without arguments" do

        it "should list all metrics" do
          metric_names = Metrics.list.map { |metric| metric['name'] }
          metric_names.sort.should == %w{foo bar baz foo_2}.sort
        end

      end

      context "with a name argument" do

        it "should list metrics that match" do
          metric_names = Metrics.list(:name => 'foo').map { |metric| metric['name'] }
          metric_names.sort.should == %w{foo foo_2}.sort
        end

      end

    end

  end
end