
module Valence
  module D2l
    class AppContext
      APP_ID_PARAMETER                = 'x_a'.freeze
      APP_KEY_PARAMETER               = 'x_b'.freeze
      CALLBACK_URL_PARAMETER          = 'x_target'.freeze
      USER_ID_CALLBACK_PARAMETER      = 'x_a'.freeze
      USER_KEY_CALLBACK_PARAMETER     = 'x_b'.freeze
      AUTHENTICATION_SERVICE_URI_PATH = '/d2l/auth/api/token'.freeze
      REQUIRED_PARAMS = [:app_id, :app_key, :timestamp_provider].freeze

      attr_reader :user_context_factory

      # @param [Hash] params
      def initialize(params={})
        fail 'Inconsistent parameters' unless params.keys.all? { |key| REQUIRED_PARAMS.include?(key) }

        params.each do |key, value|
          instance_variable_set("@#{key}", value)
        end

        @user_context_factory = UserContextFactory.new(@app_id, @app_key, @timestamp_provider)
      end

      # @param [Valence::HostSpec] authenticating_host
      # @param [URI::Generic] landing_uri
      # @return [String]
      def authentication_url(authenticating_host, landing_uri)
        uri = authenticating_host.to_uri
        uri.path = AUTHENTICATION_SERVICE_URI_PATH
        uri.query = authentication_uri_query(landing_uri)

        uri
      end

      private

      # @param [URI::Generic] callback_uri
      # @return [String]
      def authentication_uri_query(callback_uri)
        callback_url = callback_uri.to_s
        uri_hash     = Signer.encode64(@app_key, callback_url)

        params = {
          APP_ID_PARAMETER       => @app_id,
          APP_KEY_PARAMETER      => uri_hash,
          CALLBACK_URL_PARAMETER => CGI.escape(callback_url)
        }

        params.map { |k,v| "#{k}=#{v}" }.join('&')
      end
    end
  end
end