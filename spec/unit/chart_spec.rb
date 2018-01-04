require 'spec_helper'

module Librato
  describe Chart do
    let(:params) do
      {
        space_id: 0,
        type: 'line',
        name: 'test',
        streams:[{ "metric": "librato.chart.creation.spec" }]
      }
    end
    let(:chart){ described_class.new(params) }
    let(:new_chart){ chart.save }
    let(:new_chart_id) { 1 }
    let(:mock_response) do
      double(
        response_body: { chart_id: new_chart_id }.to_json
      )
    end

    describe '#initialize' do
      it 'sets required attributes' do
        expect(chart).to have_attributes(
          {
            name: params[:name],
            type: params[:type],
            streams: params[:streams],
            space_id: params[:space_id]
          }
        )
      end

      it 'raises an error for missing keys' do
        expect{ described_class.new }.to raise_error(ArgumentError)
      end
    end

    describe '#save' do
      before do
        allow_any_instance_of(Typhoeus::Request).to receive(:run).and_return(mock_response)
      end

      it 'saves the chart' do
        expect(new_chart.chart_id).to eql(new_chart_id)
      end
    end
  end
end
