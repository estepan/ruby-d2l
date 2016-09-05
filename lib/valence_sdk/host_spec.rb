module Valence
  class HostSpec
    attr_accessor :scheme, :host, :port

    def initialize(params={})
      @scheme = params[:scheme]
      @host   = params[:host]
      @port   = params[:port]
    end

    def to_uri
      case scheme.to_sym
      when :http
        URI::HTTP.build(host: host, port: port)
      when :https
        URI::HTTPS.build(host: host, port: port)
      else
        fail 'Supports only HTTP and HTTPS scheme'
      end
    end
  end
end