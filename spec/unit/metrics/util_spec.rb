require "spec_helper"

module Librato
  module Metrics

    describe Util do

      describe "#build_key_for" do
        it "builds a Hash key" do
          metric_name = "requests"
          tags = { status: 200, MeThoD: "GET", controller: "users", ACTION: "show" }
          expected = "requests%%action=show%%method=get%%controller=users%%status=200"
          actual = Util.build_key_for(metric_name, tags)

          expect(expected).to eq(actual)
        end

      end

    end

  end
end
