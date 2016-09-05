require 'spec_helper'

RSpec.describe Valence::D2l::UserContext, type: :service do
  include_context :test_constants

  shared_examples_for :has_right_parameters do
    it 'result query has right parameters' do
      data = "#{verb}&#{api_path}&#{timestamp_s}"
      app_key_signature  = Valence::D2l::Signer.encode64(app_key, data)
      user_key_signature = Valence::D2l::Signer.encode64(user_key, data)

      expect(params['x_a']).to eq app_id
      expect(params['x_b']).to eq user_id
      expect(params['x_c']).to eq app_key_signature
      expect(params['x_d']).to eq user_key_signature
    end
  end

  describe '#authenticated_uri' do
    let(:verb) { 'PUT' }
    let(:path) { api_path }

    subject { user_context.authenticated_uri(api_path, verb) }

    it_behaves_like :has_right_parameters

    context 'when full url is passed' do
      let(:path) { api_url }

      it_behaves_like :has_right_parameters
    end
  end

  # TODO: Stopped at https://github.com/Brightspace/valence-sdk-dotnet/blob/11225dd3327c6beebc77acba441644909ee8c560/lib/D2L.Extensibility.AuthSdk.UnitTests/FunctionalApiUriTests.cs#L121
end