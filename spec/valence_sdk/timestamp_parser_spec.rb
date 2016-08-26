require 'spec_helper'

RSpec.describe ValenceSdk::TimestampParser do
  describe '#try_parse_timestamp' do
    subject { described_class.new.try_parse_timestamp(response) }

    let(:response)  { "Timestamp out of range \n\n\n\n    1234" }

    it { is_expected.to eq [:ok, 1234] }

    context 'when fails to parse' do
      let(:response) { '' }

      it { is_expected.to eq [:failed, nil] }
    end
  end
end