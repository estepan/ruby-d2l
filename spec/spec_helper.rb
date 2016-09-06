require 'bundler/setup'
Bundler.setup

require 'valence_sdk'

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each {|f| require f }

RSpec.configure do |config|
  config.include(Valence)
  config.include(Valence::D2l)
end
