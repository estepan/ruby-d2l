module ValenceSdk
  class TimestampParser
    def try_parse_timestamp(timestamp_message)
      regex = /Timestamp out of range\s*(\d+)/m
      match = regex.match(timestamp_message)

      if !match.nil? && match.length >= 2
        timestamp = match[1].to_i
        return [:ok, timestamp]
      end

      return [:failed, nil]
    end
  end
end