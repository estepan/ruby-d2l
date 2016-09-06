module Valence
  class DefaultTimestampProvider
    def timestamp_ms
      (Time.now.to_f * 1000).to_i
    end
  end
end