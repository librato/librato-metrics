require "spec_helper"

module Librato
  module Metrics

    describe SmartJSON do

      describe ".read" do
        context "with MultiJSON" do
          before do
            $".delete_if {|s| s.include?("multi_json")}
            require "multi_json"
            load "lib/librato/metrics/smart_json.rb"
          end

          after do
            Object.send(:remove_const, :MultiJson)
            load "lib/librato/metrics/smart_json.rb"
          end

          it "uses .load or .decode" do
            actual = SmartJSON.read("{\"abc\":\"def\"}")

            expect(SmartJSON.handler).to eq(:multi_json)
            expect(actual).to be_a(Hash)
            expect(actual).to have_key("abc")
            expect(actual["abc"]).to eq("def")
          end
        end

        context "with JSON" do
          it "uses .parse" do
            actual = SmartJSON.read("{\"abc\":\"def\"}")

            expect(SmartJSON.handler).to eq(:json)
            expect(actual).to be_a(Hash)
            expect(actual).to have_key("abc")
            expect(actual["abc"]).to eq("def")
          end
        end
      end

      describe ".write" do
        context "with MultiJSON" do
          before do
            $".delete_if {|s| s.include?("multi_json")}
            require "multi_json"
            load "lib/librato/metrics/smart_json.rb"
          end

          after do
            Object.send(:remove_const, :MultiJson)
            load "lib/librato/metrics/smart_json.rb"
          end

          it "uses .dump or .decode" do
            actual = SmartJSON.write({abc: 'def'})

            expect(SmartJSON.handler).to eq(:multi_json)
            expect(actual).to be_a(String)
            expect(actual).to eq("{\"abc\":\"def\"}")
          end
        end

        context "with JSON" do
          it "uses .generate" do
            actual = SmartJSON.write({abc: 'def'})

            expect(SmartJSON.handler).to eq(:json)
            expect(actual).to be_a(String)
            expect(actual).to eq("{\"abc\":\"def\"}")
          end
        end
      end

    end

  end
end
