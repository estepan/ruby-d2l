require 'spec_helper'

RSpec.describe Valence::D2l::AppContext, type: :service do
  include_context :test_constants

  describe '#authentication_url' do
    let(:landing_uri) { URI(api_url) }
    let(:scheme)      { 'https' }
    let(:port)        { 443 }

    let(:expected_token_service_path) { '/d2l/auth/api/token' }

    subject { app_context.authentication_url(host_spec, landing_uri) }

    context 'when host spec defines http' do
      let(:scheme) { 'http' }

      it 'returns http schemed uri' do
        expect(subject.scheme).to eq 'http'
      end
    end

    it 'returns http schemed uri' do
      expect(subject.scheme).to eq 'https'
    end

    context 'when encoded callback passed' do
      let(:landing_uri) { escaped_callback }

      it 'respects it' do
        regex = /x_target=([^&]*)/
        match = subject.to_s.match(regex)
        callback_url = match[1]

        expect(match).to_not be_nil

        expect(CGI.escape(escaped_callback).downcase).to eq callback_url.downcase
      end
    end

    context 'when host passed' do
      let(:host) { 'asdf.com' }

      it 'respects it' do
        expect(subject.host).to eq host
      end
    end

    context 'when port passed' do
      let(:port) { 12345 }

      it 'respects it' do
        expect(subject.port).to eq port
      end
    end

    it 'returns token service path' do
      expect(subject.path).to eq expected_token_service_path
    end

    it 'respects parameters' do
      signed_uri = Valence::D2l::Signer.encode64(app_key, api_url)

      expect(params['x_a']).to eq app_id
      expect(params['x_target']).to eq CGI.escape(landing_uri.to_s)
      expect(params['x_b']).to eq signed_uri
    end

    context 'when landing url has special chars' do
      let(:landing_uri) { URI('http://univ.edu/d2l/api/resource?foo=bar') }
      let(:encoded_url) { CGI.escape(landing_uri.to_s) }

      it 'returns proper x_target param' do
        expect(params['x_target']).to eq encoded_url
      end
    end
  end
end