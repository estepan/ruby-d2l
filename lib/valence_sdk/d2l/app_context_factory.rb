module ValenceSdk
  module D2l
    class AppContextFactory
      def initialize(timestamp_provider = nil)
        self.timestamp_provider = timestamp_provider || ValenceSdk::DefaultTimestampProvider.new
      end

      def create(app_id:, app_key:)
        return AppContext.new(app_id: app_id, app_key: app_key, timestamp_provider: timestamp_provider)
      end

      private

      attr_accessor :timestamp_provider
    end
  end
end
