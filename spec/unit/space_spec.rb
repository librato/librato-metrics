require 'spec_helper'

module Librato
  describe Space do
    let(:all_spaces_response) do
      double(
        response_body: {
          spaces: [
            {
              id: 1,
              name: 'space 1'
            },
            {
              id: 2,
              name: 'space 2'
            }
          ]}.to_json
      )
    end

    let(:single_space_response) do
      double(
        response_body: {
            id: 1,
            name: 'space 1'
          }.to_json
      )
    end

    describe '.find' do
      before do
        allow_any_instance_of(Typhoeus::Request).to receive(:run).and_return(single_space_response)
      end
      it 'returns a space by id' do
        expect(Librato::Space.find(1)).to_not be_nil
      end
    end

    describe '.find_by_name' do
      before do
        allow_any_instance_of(Typhoeus::Request).to receive(:run).and_return(all_spaces_response)
      end
      it 'returns a space by name' do
        expect(Librato::Space.find_by_name('space 1')).to_not be_nil
      end
    end

    describe '.all' do
      before do
        allow_any_instance_of(Typhoeus::Request).to receive(:run).and_return(all_spaces_response)
      end
      it 'returns all spaces' do
        expect(Librato::Space.all).to be_an Array
      end
    end
  end
end
