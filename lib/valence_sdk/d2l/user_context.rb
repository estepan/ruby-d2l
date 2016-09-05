module Valence
  module D2l
    class UserContext
      APP_ID_PARAMETER = 'x_a'.freeze
      USER_ID_PARAMETER = 'x_b'.freeze
      SIGNATURE_BY_APP_KEY_PARAMETER = 'x_c'.freeze
      SIGNATURE_BY_USER_KEY_PARAMETER = 'x_d'.freeze
      TIMESTAMP_PARAMETER = 'x_t'.freeze
      REQUIRED_PARAMETERS = %i(app_id timestamp_provider app_key user_id user_key api_host)

      attr_accessor :server_skew_mills

      # Constructs a D2LUserContext with the parameters provided
      def initialize(params={})
        fail 'Inconsistent parameters' unless params.keys.all? { |key| (REQUIRED_PARAMETERS).include?(key) }

        params.each { |key, value| instance_variable_set("@#{key}", value) }

        @server_skew_mills = 0
      end

      # @return [Valence::RequestResult]
      # @param [Valence::D2l::WebException] d2l_exception
      def interpret_result(d2l_exception)
        case
        when d2l_exception.request_result.forbidden?
          interpret_forbidden(d2l_exception.response_body)
        when d2l_exception.request_result.not_found?
          Valence::RequestResult::NOT_FOUND
        when d2l_exception.request_result.internal_server_error?
          Valence::RequestResult::INTERNAL_ERROR
        when d2l_exception.request_result.bad_request?
          Valence::RequestResult::BAD_REQUEST
        else
          Valence::RequestResult::UNKNOWN_STATUS
        end
      end

      def user_context_properties
        Valence::UserContextProperties.new(
          user_id: @user_id,
          user_key: @user_key,
          scheme: @api_host.scheme,
          host_name: @api_host.host,
          port: @api_host.port
        )
      end

      def authenticated_uri(uri, http_method)
        uri = api_uri(uri) if uri.is_a?(String)

        tokens = authenticated_tokens(uri, http_method)
        query_tokens = tokens.map { |key, value| "#{key}=#{value}" }
        query_string = query_tokens.join('&')

        if uri.query != ''
          query_string = "#{uri.query}&#{query_string}"
        end

        uri.query = query_string

        uri
      end

      # Creates authentication parameters hash to be used in uri
      # @return [Hash]
      # @param [URI::Generic] uri
      # @param [String] http_method
      def authenticated_tokens(uri, http_method)
        adjusted_timestamp_seconds = adjusted_timestamp_in_seconds
        signature = format_signature(uri.path, http_method, adjusted_timestamp_seconds)
        tokens = { APP_ID_PARAMETER => @app_id }

        unless @user_id.nil?
          tokens[USER_ID_PARAMETER] = @user_id
          tokens[SIGNATURE_BY_USER_KEY_PARAMETER] = Signer.encode64(@user_key, signature)
        end

        tokens[SIGNATURE_BY_APP_KEY_PARAMETER] = Signer.encode64(@app_key, signature)
        tokens[TIMESTAMP_PARAMETER] = adjusted_timestamp_seconds.to_s

        tokens
      end

      private

      # @param [String] response_body
      # @return [String]
      def interpret_forbidden(response_body)
        if timestamp_was_changed?(response_body)
          return Valence::RequestResult::INVALID_TIMESTAMP
        end

        if response_body.dup.downcase == 'invalid token'
          return Valence::RequestResult::INVALID_SIGNATURE
        end

        Valence::RequestResult::NO_PERMISSON
      end

      # @param [String] response_body
      # @return [Boolean] Whether the timestamp was changed or not
      def timestamp_was_changed?(response_body)
        parser = Valence::TimestampParser.new
        status, server_timestamp_seconds = parser.try_parse_timestamp(response_body)

        if status == :ok
          client_timestamp = @timestamp_provider.current_timestamp_in_milliseconds
          @server_skew_mills = server_timestamp_seconds * 1000 - client_timestamp
          return true
        end

        false
      end

      # @param [String] path
      # @return [URI::Generic]
      def api_uri(path)
        uri = @api_host.to_uri

        if !path.include?('?')
          uri.path = path
        else
          path, query = path.split('?')
          uri.path = path
          uri.query = query
        end

        uri
      end

      # Returns the timestamp in milliseconds adjusting for the calculated skew
      # @return [Fixnum]
      def adjusted_timestamp_in_seconds
        timestamp = @timestamp_provider.current_timestamp_in_milliseconds

        (timestamp + @server_skew_mills) / 1000
      end

      # Formats a signature to the format required by the D2L API servers
      # @return [String]
      # @param [String] path - The absolute path for the request (ie /d2l/api/versions/)
      # @param [String] http_method - The http method used (ie GET,POST)
      # @param [Fixnum] timestamp_seconds - The timestamp to use, in seconds, for the request
      def format_signature(path, http_method, timestamp_seconds)
        # Note: We unecape the path to handle the (rare) case that the path needs to be urlencoded. The LMS checks
        # the signature of the decoded path so we must sign it appropriately.

        puts result = "#{http_method.upcase}&#{CGI.unescape(path).downcase}&#{timestamp_seconds}"
        result
      end
    end
  end
end