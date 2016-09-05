module Valence
  module D2l
    class AppContextFactory
      REQUIRED_KEYS = %w{app_id app_key}

      def initialize(timestamp_provider = nil)
        self.timestamp_provider = timestamp_provider || Valence::DefaultTimestampProvider.new
      end

      def create(params = {})
        params.each { |key, value| fail "#{key.to_sym} is required" if value.nil? }

        AppContext.new(app_id: params[:app_id],
                       app_key: params[:app_key],
                       timestamp_provider: timestamp_provider)
      end

      private

      attr_accessor :timestamp_provider
    end
  end
end
