module Valence
  module D2l
    class UserContextFactory
      # @param [Valence::DefaultTimestampFactory] timestamp_provider
      # @param [String] app_key
      # @param [String] app_id
      def initialize(app_id, app_key, timestamp_provider=nil)
        @app_id = app_id
        @app_key = app_key
        @timestamp_provider = timestamp_provider || Valence::DefaultTimestampProvider.new
      end

      # @param [Hash] A hash containing proper parameters to initialize UserContext
      # user_id [String], user_key [String], api_host [Valence::HostSpec]
      # user_context_properties [Valence::UserContextProperties]
      # authentication_callback_uri [URI::Generic], api_host [Valence::HostSpec]
      def create(params)
        case
        when params[:user_id] && params[:user_key] && params[:api_host]
          create_user_context_default(params[:user_id], params[:user_key], params[:api_host])
        when params[:user_context_properties]
          create_user_context_with_user_props(params[:user_context_properties])
        when params[:authentication_callback_uri] && params[:api_host]
          create_user_context_with_callback(params[:authentication_callback_uri], params[:api_host])
        else
          fail 'Inconsistent parameters'
        end
      end

      def create_anonymous(api_host)
        create_user_context_default(nil, nil, api_host)
      end

      private

      # @param [Valence::HostSpec] api_host
      # @param [URI::Generic] authentication_callback_uri
      # @return [Valence::D2l::UserContext]
      def create_user_context_with_callback(authentication_callback_uri, api_host)
        parsing_result = CGI.parse(authentication_callback_uri.query)

        user_id = parsing_result[USER_ID_CALLBACK_PARAMETER]
        user_key = parsing_result[USER_KEY_CALLBACK_PARAMETER]

        return nil if user_id.nil? || user_key.nil?

        create_user_context(user_id, user_key, api_host)
      end

      # @param [Valence::HostSpec] api_host
      # @param [String] user_key
      # @param [String] user_id
      # @return [Valence::D2l::UserContext]
      def create_user_context_default(user_id, user_key, api_host)
        UserContext.new(
            timestamp_provider: @timestamp_provider,
            app_id: @app_id,
            app_key: @app_key,
            user_id: user_id,
            user_key: user_key,
            api_host: api_host
        )
      end

      # @param [Valence::UserContextProperties] user_context_properties
      # @return [Valence::D2l::UserContext]
      def create_user_context_with_user_props(user_context_properties)
        api_host = HostSpec.new(
            host: user_context_properties.host,
            scheme: user_context_properties.scheme,
            port: user_context_properties.port
        )

        user_id = user_context_properties.user_id
        user_key = user_context_properties.user_key

        create_user_context(user_id, user_key, api_host)
      end
    end
  end
end
