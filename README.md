Librato Metrics
=======

[![Build Status](https://secure.travis-ci.org/librato/librato-metrics.png?branch=master)](http://travis-ci.org/librato/librato-metrics)

A convenient Ruby wrapper for the Librato Metrics API.

## Installation

In your shell:

    gem install librato-metrics

Then, in your application or script:

    require 'librato/metrics'
    
### Optional steps

For best performance we recommend installing [yajl-ruby](https://github.com/brianmario/yajl-ruby):

    gem install yajl-ruby

## Quick Start

If you are looking for the quickest possible route to getting a data into Metrics, you only need two lines:

    Librato::Metrics.authenticate 'email', 'api_key'
    Librato::Metrics.submit :my_metric => 42, :my_other_metric => 1002

Unspecified metrics will send a *gauge*, but if you need to send a different metric type or include additional properties, simply use a hash:

    Librato::Metrics.submit :my_metric => {:type => :counter, :value => 1002, :source => 'myapp'}

While this is all you need to get started, if you are sending a number of metrics regularly a queue may be easier/more performant so read on...

## Authentication

Make sure you have [an account for Metrics](https://metrics.librato.com/) and then authenticate with your email and API key (on your account page):

    Librato::Metrics.authenticate 'email', 'api_key'

## Sending Measurements

If you are sending very many measurements or sending them very often, it will be much higher performance to bundle them up together to reduce your request volume. Use `Queue` for this.

Queue up a simple gauge metric named `temperature`:

    queue = Librato::Metrics::Queue.new
    queue.add :temperature => 32.2
    
While symbols are used by convention for metric names, strings will work just as well:

	queue.add 'myapp.request_time' => 86.7

If you are tracking measurements over several seconds/minutes, the queue will handle storing measurement time for you (otherwise all metrics will be recorded as measured when they are submitted). 

If you want to specify a time other than queuing time for the measurement:

	# use a epoch integer
	queue.add :humidity => {:measure_time => 1336508422, :value => 48.2}
	
	# use a Time object to correct for a 5 second delay
	queue.add :humidity => {:measure_time => Time.now-5, :value => 37.6}

You can queue multiple metrics at once. Here's a gauge (`load`) and a counter (`visits`):

    queue.add :load => 2.2, :visits => {:type => :counter, :value => 400}

Queue up a metric with a specified source:

    queue.add :cpu => {:source => 'app1', :value => 92.6}

A complete [list of metric attributes](http://dev.librato.com/v1/metrics) is available in the [API documentation](http://dev.librato.com/v1).

Send currently queued measurements to Metrics:

    queue.submit

## Aggregate Measurements

If you are measuring something very frequently e.g. per-request in a web application (order mS)  you may not want to send each individual measurement, but rather periodically send a [single aggregate measurement](http://dev.librato.com/v1/post/metrics#gauge_specific), spanning multiple seconds or even minutes. Use an `Aggregator` for this.

Aggregate a simple gauge metric named `response_latency`:

    aggregator = Librato::Metrics::Aggregator.new
    aggregator.add :response_latency => 85.0
    aggregator.add :response_latency => 100.5
    aggregator.add :response_latency => 150.2
    aggregator.add :response_latency => 90.1
    aggregator.add :response_latency => 92.0

Which would result in a gauge measurement like:

    {:name => "response_latency", :count => 5, :sum => 517.8, :min => 85.0, :max => 150.2}

You can specify a source during aggregate construction:

    aggregator = Librato::Metrics::Aggregator.new(:source => 'foobar')

You can aggregate multiple metrics at once:

    aggregator.add :app_latency => 35.2, :db_latency => 120.7

Send the currently aggregated metrics to Metrics:

    aggregator.submit

## Benchmarking

If you have operations in your application you want to record execution time for, both `Queue` and `Aggregator` support the `#time` method:

    aggregator.time :my_measurement do
      # do work...
    end

The difference between the two is that `Queue` submits each timing measurement individually, while `Aggregator` submits a single timing measurement spanning all executions.

If you need extra attributes for a `Queue` timing measurement, simply add them on:

    queue.time :my_measurement, :source => 'app1' do
      # do work...
    end
    
## Auto-Submitting Metrics

Both `Queue` and `Aggregator` support automatically submitting measurements on a given time interval:

	# submit once per minute
	timed_queue = Librato::Metrics::Queue.new(:autosubmit_interval => 60)
	
	# submit every 5 minutes
	timed_aggregator = Librato::Metrics::Aggregator.new(:autosubmit_interval => 300)
	
`Queue` also supports auto-submission based on measurement volume:

	# submit when the 400th measurement is queued
	volume_queue = Librato::Metrics::Queue.new(:autosubmit_count => 400)

These options can also be combined for more flexible behavior. 

Both options are driven by the addition of measurements. Specifically for time-based autosubmission if you are adding measurements irregularly (less than once per second), submission may lag past your specified interval until the next measurement is added.

## Querying Metrics

Get name and properties for all metrics you have in the system:

    metrics = Librato::Metrics.list

Get only metrics whose name includes `time`:

    metrics = Librato::Metrics.list :name => 'time'

## Querying Metric Data

Get attributes for metric `temperature`:

    data = Librato::Metrics.fetch :temperature

Get the 20 most recent data points for `temperature`:

    data = Librato::Metrics.fetch :temperature, :count => 20

Get the 20 most recent data points for `temperature` from a specific source:

    data = Librato::Metrics.fetch :temperature, :count => 20, :source => 'app1'

Get the 20 most recent 15 minute data point rollups for `temperature`:

    data = Librato::Metrics.fetch :temperature, :count => 20, :resolution => 900

There are many more options supported for querying, take a look at the [REST API docs](http://dev.librato.com/v1/get/gauges/:name) or the [fetch documentation](http://rubydoc.info/github/librato/librato-metrics/master/Librato/Metrics.fetch)  for more details.

## Deleting Metrics

If you ever need to remove a metric and all of its measurements, doing so is easy:

	# Delete the metrics 'temperature' and 'humidity'
	Librato::Metrics.delete :temperature, :humidity
	
Note that deleted metrics and their measurements are unrecoverable, so use with care.

## Using Multiple Accounts Simultaneously

If you need to use metrics with multiple sets of authentication credentials simultaneously, you can do it with `Client`:

    joe = Librato::Metrics::Client.new
    joe.authenticate 'email1', 'api_key1'
    
    mike = Librato::Metrics::Client.new
    mike.authenticate 'email2', 'api_key2'

All of the same operations you can call directly from `Librato::Metrics` are available per-client:

	# list Joe's metrics
	joe.list
	
	# fetch the last 20 data points for Mike's metric, humidity 
	mike.fetch :humidity, :count => 20
	
There are two ways to associate a new queue with a client:

	# these are functionally equivalent
	joe_queue = Librato::Metrics::Queue.new(:client => joe)
	joe_queue = joe.new_queue
    
Once the queue is associated you can use it normally:

	joe_queue.add :temperature => {:source => 'sf', :value => 65.2}
	joe_queue.submit

## Thread Safety

The `librato-metrics` gem currently does not do internal locking for thread safety. When used in multi-threaded applications, please add your own mutexes for sensitive operations.

## Feature Roadmap

These are features we expect to add in future versions, roughly in the order of current priority. If you feel strongly about a feature, feel free to [create an issue](https://github.com/librato/librato-metrics/issues) or [join us in live chat](https://librato.campfirenow.com/269d3) and talk to us about it.

* Queue objects support a single default measure_time to use for any measurements which don't have it set
* Queues auto-submit when they hit a set number of records
* Queues auto-submit when they hit a max time interval
* Query actions return a collection object which auto-paginates large result sets

## Contribution

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project and submit a pull request from a feature or bugfix branch.
* Please review our [code conventions](https://github.com/librato/librato-metrics/wiki/Code-Conventions).
* Please include specs. This is important so we don't break your changes unintentionally in a future version.
* Please don't modify the gemspec, Rakefile, version, or changelog. If you do change these files, please isolate a separate commit so we can cherry-pick around it.

## Copyright

Copyright (c) 2011-2012 [Librato Inc.](http://librato.com) See LICENSE for details.
