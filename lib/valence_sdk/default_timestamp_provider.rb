module ValenceSdk
  class DefaultTimestampProvider
    def current_timestamp_in_milliseconds
      (Time.now.to_f * 1000).to_i
    end
  end
end