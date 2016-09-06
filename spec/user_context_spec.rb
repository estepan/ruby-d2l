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

    specify 'verb case does nothing' do
      expected_url = user_context.authenticated_uri(api_path, 'GET').to_s
      actual_url   = user_context.authenticated_uri(api_path, 'get').to_s

      expect(actual_url).to eq expected_url
    end

    specify 'path case does nothing' do
      expected_url = user_context.authenticated_uri('/d2l/api/someresource', 'GET').to_s
      actual_url   = user_context.authenticated_uri('/d2l/api/SomeResource', 'GET').to_s

      expect(actual_url).to eq expected_url
    end

    context 'when path query string is present' do
      let(:api_path) { api_path_with_query }

      it 'respects it' do
        expect(subject.query).to include URI(api_path).query
        expect(params['bar']).to eq 'baz'
        expect(params['x_a']).to_not be_empty
      end
    end

    context 'when endpoint settings provided' do
      let(:scheme) { 'HTTP' }
      let(:host)   { 'myuniv.edu' }
      let(:port)   { 1905 }

      it 'respects them' do
        expect(subject.scheme).to eq 'http'
        expect(subject.host).to eq 'myuniv.edu'
        expect(subject.port).to eq 1905
      end
    end

    context 'when full url is passed' do
      let(:path) { api_url }

      it_behaves_like :has_right_parameters
    end

    context 'when timestamp is adjusted' do
      let(:server_clock_skew_ms) { 225000 }
      let(:timestamp_provider)   { double timestamp_ms: (timestamp_ms - server_clock_skew_ms) }

      it 'provides correct timestamp' do
        user_context.server_skew_ms = server_clock_skew_ms
        subject
        expect(params['x_t']).to eq timestamp_s.to_s
      end

      it 'provides correct signature' do
        data = "#{verb}&#{api_path}&#{timestamp_s}"
        app_key_signature  = Valence::D2l::Signer.encode64(app_key, data)

        user_context.server_skew_ms = server_clock_skew_ms
        subject
        expect(params['x_c']).to eq app_key_signature
      end
    end

    context 'for anonymous user context' do
      let(:user_context) { anon_user_context }

      it 'result query has right parameters' do
        data = "#{verb}&#{api_path}&#{timestamp_s}"
        app_key_signature  = Valence::D2l::Signer.encode64(app_key, data)

        expect(params['x_a']).to eq app_id
        expect(params['x_c']).to eq app_key_signature
      end

      context 'when timestamp is adjusted' do
        let(:server_clock_skew_ms) { 225000 }
        let(:timestamp_provider)   { double timestamp_ms: (timestamp_ms - server_clock_skew_ms) }

        it 'provides correct timestamp' do
          user_context.server_skew_ms = server_clock_skew_ms
          subject
          expect(params['x_t']).to eq timestamp_s.to_s
        end
      end
    end
  end

  describe '#interpret_result' do
    let(:response_body) { nil }
    let(:status_code)   { nil }
    let(:d2l_exception) { Valence::D2l::WebException.new(status_code, response_body) }

    subject { user_context.interpret_result(d2l_exception) }

    context 'when status 403' do
      let(:status_code) { 403 }

      it { is_expected.to eq Valence::RequestResult::NO_PERMISSON }

      context 'when token invalid' do
        let(:response_body) { 'Invalid token' }

        it { is_expected.to eq Valence::RequestResult::INVALID_SIGNATURE }
      end

      context 'when timestamp differs' do
        let(:timestamp_s)        { 1319000000 }
        let(:timestamp_provider) { double timestamp_ms: 1000 * timestamp_s }
        let(:user_context)       { anon_user_context }

        let(:server_ahead_by_s) { 907 }
        let(:response_body) { "Timestamp out of range \r\n#{timestamp_s + server_ahead_by_s}" }

        it 'changes server skew by timestamp difference' do
          expect { subject }.to change { user_context.server_skew_ms }.to(server_ahead_by_s * 1000)
        end
      end

      context 'when response timestamp is invalid' do
        let(:response_body) { "Timestamp is out of range\r\n" }

        it 'does not change skew' do
          user_context.server_skew_ms = 874_000
          expect { subject }.not_to change { user_context.server_skew_ms }
        end
      end
    end

    context 'when status code 401' do
      let(:status_code) { 401 }

      it { is_expected.to eq Valence::RequestResult::BAD_REQUEST }
    end

    context 'when status code 404' do
      let(:status_code) { 404 }

      it { is_expected.to eq Valence::RequestResult::NOT_FOUND }
    end

    context 'when status code 500' do
      let(:status_code) { 500 }

      it { is_expected.to eq Valence::RequestResult::INTERNAL_ERROR }
    end

    context 'when status code 502' do
      let(:status_code) { 502 }

      it { is_expected.to eq Valence::RequestResult::UNKNOWN_STATUS }
    end
  end
end
