module ValenceSdk
  class UserContextProperties
    PARAMS = [:user_id, :user_key, :scheme, :host, :port]
    attr_accessor *PARAMS

    def initialize(params={})
      params.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end
  end
end