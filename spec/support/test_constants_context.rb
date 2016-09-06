shared_context :test_constants do
  let(:app_id)              { 'foo' }
  let(:app_key)             { 'asdfghjkasdfghjk' }
  let(:scheme)              { 'https' }
  let(:host)                { 'authenticationhost.com' }
  let(:port)                { 44444 }
  let(:user_id)             { '42' }
  let(:user_key)            { 'qwertyuiopqwertyuiop' }
  let(:api_url)             { 'http://univ.edu/d2l/api/lp/1.0/organization/info' }
  let(:escaped_callback)    { 'http://sample/abc%20xyz/?test=foo+bar&magic=true' }
  let(:api_path)            { '/d2l/api/lp/1.0/organization/info' }
  let(:api_path_with_query) { '/foo?bar=baz' }
  let(:api_path_query)      { 'bar=baz' }
  let(:timestamp_ms)        { 1234567890 }
  let(:timestamp_s)         { 1234567 }

  let(:host_spec)           { Valence::HostSpec.new(scheme: scheme, host: host, port: port) }
  let(:timestamp_provider)  { double timestamp_ms: timestamp_ms }

  let(:params) { Hash[subject.query.split('&').map { |value| value.split('=') }.compact.reject(&:empty?)] }

  let(:app_context) do
    factory = Valence::D2l::AppContextFactory.new(timestamp_provider)
    factory.create(app_id: app_id, app_key: app_key)
  end

  let(:user_context) do
    app_context.user_context_factory.create(user_id:  user_id,
                                            user_key: user_key,
                                            api_host: host_spec)
  end

  let(:anon_user_context) do
    app_context.user_context_factory.create_anonymous(host_spec)
  end
end