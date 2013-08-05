require 'librato/metrics'

Librato::Metrics.authenticate 'my email', 'my api key'

# send a measurement of 12 for 'foo'
Librato::Metrics.submit :cpu => 54

# submit multiple metrics at once
Librato::Metrics.submit :cpu => 63, :memory => 213

# submit a metric with a custom source
Librato::Metrics.submit :cpu => {:source => 'myapp', :value => 75}

# if you are sending many metrics it is much more performant
# to submit them in sets rather than individually:

queue = Librato::Metrics::Queue.new

queue.add 'disk.free' => 1223121
queue.add :memory => 2321
queue.add :cpu => {:source => 'myapp', :value => 52}
#...

queue.submit