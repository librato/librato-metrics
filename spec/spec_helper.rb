$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'rspec/mocks/standalone'

require 'librato/metrics'

RSpec.configure do |config|

end