# send a set of metrics every 60 seconds

require 'librato/metrics'

Librato::Metrics.authenticate 'my email', 'my api key'
queue = Librato::Metrics::Queue.new

def sleep_until(time)
  secs = time - Time.now
  puts "sleeping for #{secs}"
  sleep secs
end

loop do
  start = Time.now

  queue.add 'my.metric' => 1234
  # do work, add more metrics..

  begin
    queue.submit
  rescue Exception => e
    $stderr.puts e
  end

  sleep_until(start+60)
end