module Valence
  class RequestResult
    FORBIDDEN         = 'forbidden'.freeze
    BAD_REQUEST       = 'bad_request'.freeze
    NOT_FOUND         = 'not_found'.freeze
    INTERNAL_ERROR    = 'internal_server_error'.freeze
    UNKNOWN_STATUS    = 'unknown'.freeze
    INVALID_TIMESTAMP = 'invalid_timestamp'.freeze
    INVALID_SIGNATURE = 'invalid_signature'.freeze
    NO_PERMISSON      = 'no_permission'.freeze

    STATUS_CODES_MAPPING = { '403' => FORBIDDEN,
                             '401' => BAD_REQUEST,
                             '404' => NOT_FOUND,
                             '500' => INTERNAL_ERROR }

    def initialize(status_code)
      @status_code = status_code
    end

    attr_reader :status_code

    def forbidden?
      error_name == FORBIDDEN
    end

    def not_found?
      error_name == NOT_FOUND
    end

    def internal_server_error?
      error_name == INTERNAL_ERROR
    end

    def bad_request?
      error_name == BAD_REQUEST
    end

    private

    def error_name
      STATUS_CODES_MAPPING[@status_code.to_s] || UNKNOWN_STATUS
    end
  end
end