require 'openssl'
require 'Base64'

module ValenceSdk
  module D2l
    class Signer
      private

      def self.encode64(key, data)
        Base64.encode64(compute_hash(key, data)).strip()
      end

      def self.compute_hash(key, data)
        OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, data)
      end
    end
  end
end