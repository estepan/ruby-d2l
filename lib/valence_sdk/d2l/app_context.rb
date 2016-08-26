module ValenceSdk
  module D2l
    class AppContext
      APP_ID_PARAMETER                = 'x_a'
      APP_KEY_PARAMETER               = 'x_b'
      CALLBACK_URL_PARAMETER          = 'x_target'
      USER_ID_CALLBACK_PARAMETER      = 'x_a'
      USER_KEY_CALLBACK_PARAMETER     = 'x_b'
      AUTHENTICATION_SERVICE_URI_PATH = '/d2l/auth/api/token'
      REQUIRED_PARAMS = [:app_id, :app_key, :timestamp_provider].freeze

      def initialize(params={})
        fail 'Inconsistent parameters' unless params.keys.all? { |key| REQUIRED_PARAMS.include?(key) }

        params.each do |key, value|
          instance_variable_set("@#{key}", value)
        end
      end


      # @param [ValenceSdk::HostSpec] authenticating_host
      # @param [URI::Generic] landing_uri
      def create_url_for_authentication(authenticating_host, landing_uri)
        uri = authenticating_host.to_uri
        uri.path = AUTHENTICATION_SERVICE_URI_PATH
        uri.query = build_authentication_uri_query_string(landing_uri)

        return uri.to_s
      end

      # @param [ValenceSdk::HostSpec] api_host
      # @param [URI::Generic] authentication_callback_uri
      def create_user_context(params={})
        user_context_properties = params[:user_context_properties]
        api_host = HostSpec.new(
            host:   user_context_properties.try(:host),
            scheme: user_context_properties.try(:scheme),
            port:   user_context_properties.try(:port)
        )

        user_id  = params[:user_id] || user_context_properties.try(:[], :user_id)
        user_key = params[:user_key] || user_context_properties.try(:[], :user_key)
        api_host ||= params[:api_host]

        authentication_callback_uri = params[:authentication_callback_uri]

        if  (user_key.nil? || user_id.nil?)
          parsing_result = CGI.parse(authentication_callback_uri.query)

          user_id = parsing_result[USER_ID_CALLBACK_PARAMETER]
          user_key = parsing_result[USER_KEY_CALLBACK_PARAMETER]

          return nil if user_id.nil? || user_key.nil?
        end

        UserContext.new(
            timestamp_provider: @timestamp_provider,
            app_id:   @app_id,
            app_key:  @app_key,
            user_id:  user_id,
            user_key: user_key,
            api_host: api_host
        )
      end

      def create_anonymous_user_context(api_host)
        # STOPPED HERE
      end

      def build_authentication_uri_query_string(landing_uri)
        # code here
      end
    end
  end
end