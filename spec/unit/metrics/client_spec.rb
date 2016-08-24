require 'spec_helper'

module Librato
  module Metrics

    describe Client do

      describe "#tags" do
        context "when set" do
          before { subject.tags = { instance: "i-1234567a" } }
          after { Librato::Metrics.client.tags.clear }
          it "gets @tags" do
            expect(subject.tags).to be_a(Hash)
            expect(subject.tags.keys).to include(:instance)
            expect(subject.tags[:instance]).to eq("i-1234567a")
          end
        end

        context "when not set" do
          it "defaults to empty hash" do
            expect(subject.tags).to be_empty
          end
        end
      end

      describe "#tags=" do
        after { Librato::Metrics.client.tags.clear }
        it "sets @tags" do
          expected_tags = { instance: "i-1234567b" }
          expect{subject.tags = expected_tags}.to change{subject.tags}.from({}).to(expected_tags)
          expect(subject.tags).to be_a(Hash)
          expect(subject.tags.keys).to eq(expected_tags.keys)
          expect(subject.tags[:instance]).to eq(expected_tags[:instance])
        end

        context "when invalid argument" do
          it "raises exception" do
            expect { subject.tags = "invalid arg" }.to raise_error(ArgumentError)
          end
        end
      end

      describe "#add_tags" do
        after { Librato::Metrics.client.tags.clear }

        context "when no existing tags" do
          it "adds top-level tags" do
            expected_tags = { instance: "i-1234567c" }
            subject.add_tags expected_tags

            expect(subject.tags).to be_a(Hash)
            expect(subject.tags.keys).to eq(expected_tags.keys)
            expect(subject.tags[:instance]).to eq(expected_tags[:instance])
          end
        end

        context "when existing tags" do
          it "merges tags" do
            tmp1 = { instance: "i-1234567d" }
            tmp2 = { region: "us-east-1", elb: "metrics-stg" }
            expected_tags = tmp1.merge(tmp2)

            subject.add_tags tmp1
            subject.add_tags tmp2

            expect(subject.tags).to be_a(Hash)
            expect(subject.tags.keys).to eq(expected_tags.keys)
            expect(subject.tags[:instance]).to eq(expected_tags[:instance])
            expect(subject.tags[:region]).to eq(expected_tags[:region])
            expect(subject.tags[:elb]).to eq(expected_tags[:elb])
          end
        end

        context "when invalid argument" do
          it "raises exception" do
            expect { subject.add_tags "invalid arg" }.to raise_error(ArgumentError)
          end
        end
      end

      describe "#agent_identifier" do
        context "when given a single string argument" do
          it "sets agent_identifier" do
            subject.agent_identifier 'mycollector/0.1 (dev_id:foo)'
            expect(subject.agent_identifier).to eq('mycollector/0.1 (dev_id:foo)')
          end
        end

        context "when given three arguments" do
          it "composes an agent string" do
            subject.agent_identifier('test_app', '0.5', 'foobar')
            expect(subject.agent_identifier).to eq('test_app/0.5 (dev_id:foobar)')
          end

          context "when given an empty string" do
            it "sets to empty" do
              subject.agent_identifier ''
              expect(subject.agent_identifier).to be_empty
            end
          end
        end

        context "when given two arguments" do
          it "raises error" do
            expect { subject.agent_identifier('test_app', '0.5') }.to raise_error(ArgumentError)
          end
        end
      end

      describe "#api_endpoint" do
        it "defaults to metrics" do
          expect(subject.api_endpoint).to eq('https://metrics-api.librato.com')
        end
      end

      describe "#api_endpoint=" do
        it "sets api_endpoint" do
          subject.api_endpoint = 'http://test.com/'
          expect(subject.api_endpoint).to eq('http://test.com/')
        end

        # TODO:
        # it "should ensure trailing slash"
        # it "should ensure real URI"
      end

      describe "#authenticate" do
        context "when given two arguments" do
          it "stores them as email and api_key" do
            subject.authenticate 'test@librato.com', 'api_key'
            expect(subject.email).to eq('test@librato.com')
            expect(subject.api_key).to eq('api_key')
          end
        end
      end

      describe "#connection" do
        it "raises exception without authentication" do
          subject.flush_authentication
          expect { subject.connection }.to raise_error(Librato::Metrics::CredentialsMissing)
        end
      end

      describe "#faraday_adapter" do
        it "defaults to Metrics default adapter" do
          Metrics.faraday_adapter = :typhoeus
          expect(Client.new.faraday_adapter).to eq(Metrics.faraday_adapter)
          Metrics.faraday_adapter = nil
        end
      end

      describe "#faraday_adapter=" do
        it "allows setting of faraday adapter" do
          subject.faraday_adapter = :excon
          expect(subject.faraday_adapter).to eq(:excon)
          subject.faraday_adapter = :patron
          expect(subject.faraday_adapter).to eq(:patron)
        end
      end

      describe "#new_queue" do
        it "returns a new queue with client set" do
          queue = subject.new_queue
          expect(queue.client).to eq(subject)
        end
      end

      describe "#persistence" do
        it "defaults to direct" do
          subject.send(:flush_persistence)
          expect(subject.persistence).to eq(:direct)
        end

        it "allows configuration of persistence method" do
          subject.persistence = :fake
          expect(subject.persistence).to eq(:fake)
        end
      end

      describe "#submit" do
        it "persists metrics immediately" do
          subject.authenticate 'me@librato.com', 'foo'
          subject.persistence = :test
          expect(subject.submit(foo: 123)).to be true
          expect(subject.persister.persisted).to eq({gauges: [{name: 'foo', value: 123}]})
        end

        it "tolerates muliple metrics" do
          subject.authenticate 'me@librato.com', 'foo'
          subject.persistence = :test
          expect { subject.submit foo: 123, bar: 456 }.not_to raise_error
          expected = {gauges: [{name: 'foo', value: 123}, {name: 'bar', value: 456}]}
          expect(subject.persister.persisted).to equal_unordered(expected)
        end
      end

    end

  end
end
