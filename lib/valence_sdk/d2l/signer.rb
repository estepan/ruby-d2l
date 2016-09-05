require 'openssl'
require 'Base64'

module Valence
  module D2l
    class Signer
      def self.encode64(key, data)
        result = Base64.encode64(compute_hash(key, data))

        result.gsub('=', '').gsub('+', '-').gsub('/', '_').strip
      end

      def self.compute_hash(key, data)
        OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, data)
      end
    end
  end
end