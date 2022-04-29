Librato Metrics
=======

[![Gem Version](https://badge.fury.io/rb/librato-metrics.png)](http://badge.fury.io/rb/librato-metrics) [![Build Status](https://secure.travis-ci.org/librato/librato-metrics.png?branch=master)](http://travis-ci.org/librato/librato-metrics) [![Code Climate](https://codeclimate.com/github/librato/librato-metrics.png)](https://codeclimate.com/github/librato/librato-metrics)

A convenient Ruby wrapper for the Librato Metrics API.

---

## Important note on breaking change

**NOTE:** Starting with version 2.1.0 librato-metrics requires a Librato account that [supports tagged metrics](https://www.librato.com/docs/kb/faq/account_questions/tags_or_sources/). If your Librato account doesn't yet support tagged metrics please use the [1.6.1 version](https://rubygems.org/gems/librato-metrics/versions/1.6.1).

---

This gem provides granular control for scripting interactions with the Metrics core API. It is well suited for integrations, scripts, workers & background jobs. If you want to submit from a web app, take at look at [librato-rails](https://github.com/librato/librato-rails) and/or [librato-rack](https://github.com/librato/librato-rack).

## Installation

In your shell:

    gem install librato-metrics

Then, in your application or script:

    require 'librato/metrics'

### Optional steps

For best performance we recommend installing [yajl-ruby](https://github.com/brianmario/yajl-ruby):

    gem install yajl-ruby

If you are using jruby, you need to ensure [jruby-openssl](https://github.com/jruby/jruby-ossl) is available:

    gem install jruby-openssl

## Quick Start

If you are looking for the quickest possible route to getting a data into Metrics, you only need two lines:

```ruby
Librato::Metrics.authenticate 'email', 'api_key'
Librato::Metrics.submit my_metric: { value: 42, tags: { host: 'localhost' } }
```

While this is all you need to get started, if you are sending a number of metrics regularly a queue may be easier/more performant so read on...


## Authentication

Make sure you have [an account for Librato](https://metrics.librato.com/) and then authenticate with your email and API key (on your account page):

```ruby
Librato::Metrics.authenticate 'email', 'api_key'
```

## Sending Measurements

A measurement includes a metric name, value, and one or more tags. Tags include a name/value pair that describe a particular data stream. Each unique tag set creates an individual metric stream which can later be filtered and aggregated along.

Queue up a simple metric named `temperature`:

```ruby
queue = Librato::Metrics::Queue.new
queue.add temperature: {value: 77, tags: { city: 'oakland' }}
queue.submit
```

### Top-Level Tags

You can initialize `Queue` and/or `Aggregator` with top-level tags that will be applied to every measurement:

```ruby
queue = Librato::Metrics::Queue.new(tags: { service: 'auth', environment: 'prod', host: 'auth-prod-1' })
queue.add my_metric: 10
queue.submit
```

### Per-Measurement Tags

Optionally, you can submit per-measurement tags by passing a tags Hash when adding measurements:

```ruby
queue.add my_other_metric: { value: 25, tags: { db: 'rr1' } }
queue.submit
```

For more information, visit the [API documentation](https://www.librato.com/docs/api/#create-a-measurement).


## Querying Metrics

Get name and properties for all metrics you have in the system:

```ruby
metrics = Librato::Metrics.metrics
```

Get only metrics whose name includes `time`:

```ruby
metrics = Librato::Metrics.metrics name: 'time'
```

## Retrieving Measurements

Get the series for `exceptions` in **production** grouped by **sum** within the **last hour**:

```ruby
query = {
  resolution: 1,
  duration: 3600,
  group_by: "environment",
  group_by_function: "sum",
  tags_search: "environment=prod*"
}
Librato::Metrics.get_series :exceptions, query
```

For more information, visit the [API documentation](https://www.librato.com/docs/api/#retrieve-a-measurement).


## Aggregate Measurements

If you are measuring something very frequently e.g. per-request in a web application (order mS)  you may not want to send each individual measurement, but rather periodically send a [single aggregate measurement](https://www.librato.com/docs/api/#gauge-specific-parameters), spanning multiple seconds or even minutes. Use an `Aggregator` for this.

Aggregate a simple gauge metric named `response_latency`:

```ruby
aggregator = Librato::Metrics::Aggregator.new
aggregator.add response_latency: 85.0
aggregator.add response_latency: 100.5
aggregator.add response_latency: 150.2
aggregator.add response_latency: 90.1
aggregator.add response_latency: 92.0
```

Which would result in a gauge measurement like:

```ruby
{name: "response_latency", count: 5, sum: 517.8, min: 85.0, max: 150.2}
```

You can specify a source during aggregate construction:

```ruby
aggregator = Librato::Metrics::Aggregator.new(tags: { service: 'auth', environment: 'prod', host: 'auth-prod-1' })
```

You can aggregate multiple metrics at once:

```ruby
aggregator.add app_latency: 35.2, db_latency: 120.7
```

Send the currently aggregated metrics to Metrics:

```ruby
aggregator.submit
```

## Benchmarking

If you have operations in your application you want to record execution time for, both `Queue` and `Aggregator` support the `#time` method:

```ruby
aggregator.time :my_measurement do
  # do work...
end
```

The difference between the two is that `Queue` submits each timing measurement individually, while `Aggregator` submits a single timing measurement spanning all executions.

If you need extra attributes for a `Queue` timing measurement, simply add them on:

```ruby
queue.time :my_measurement do
  # do work...
end
```

## Annotations

Annotation streams are a great way to track events like deploys, backups or anything else that might affect your system. They can be overlaid on any other metric stream so you can easily see the impact of changes.

At a minimum each annotation needs to be assigned to a stream and to have a title. Let's add an annotation for deploying `v45` of our app to the `deployments` stream:

```ruby
Librato::Metrics.annotate :deployments, 'deployed v45'
```

There are a number of optional fields which can make annotations even more powerful:

```ruby
Librato::Metrics.annotate :deployments, 'deployed v46', source: 'frontend',
    start_time: 1354662596, end_time: 1354662608,
    description: 'Deployed 6f3bc6e67682: fix lotsa bugs…'
```

You can also automatically annotate the start and end time of an action by using `annotate`'s block form:

```ruby
Librato::Metrics.annotate :deployments, 'deployed v46' do
  # do work..
end
```

More fine-grained control of annotations is available via the `Annotator` object:

```ruby
annotator = Librato::Metrics::Annotator.new

# list annotation streams
streams = annotator.list

# fetch a list of events in the last hour from a stream
annotator.fetch :deployments, start_time: (Time.now.to_i-3600)

# delete an event
annotator.delete_event 'deployments', 23
```

See the documentation of `Annotator` for more details and examples of use.

## Auto-Submitting Metrics

Both `Queue` and `Aggregator` support automatically submitting measurements on a given time interval:

```ruby
# submit once per minute
timed_queue = Librato::Metrics::Queue.new(autosubmit_interval: 60)

# submit every 5 minutes
timed_aggregator = Librato::Metrics::Aggregator.new(autosubmit_interval: 300)
```

`Queue` also supports auto-submission based on measurement volume:

```ruby
# submit when the 400th measurement is queued
volume_queue = Librato::Metrics::Queue.new(autosubmit_count: 400)
```

These options can also be combined for more flexible behavior.

Both options are driven by the addition of measurements. *If you are adding measurements irregularly (less than once per second), time-based submission may lag past your specified interval until the next measurement is added.*

If your goal is to collect metrics every _x_ seconds and submit them, [check out this code example](https://github.com/librato/librato-metrics/blob/master/examples/submit_every.rb).

## Setting Metric Properties

Setting custom [properties](https://www.librato.com/docs/api/#metric-attributes) on your metrics is easy:

```ruby
# assign a period and default color
Librato::Metrics.update_metric :temperature, period: 15, attributes: { color: 'F00' }
```

## Deleting Metrics

If you ever need to remove a metric and all of its measurements, doing so is easy:

```ruby
# delete the metrics 'temperature' and 'humidity'
Librato::Metrics.delete_metrics :temperature, :humidity
```

You can also delete using wildcards:

```ruby
# delete metrics that start with cpu. except for cpu.free
Librato::Metrics.delete_metrics names: 'cpu.*', exclude: ['cpu.free']
```

Note that deleted metrics and their measurements are unrecoverable, so use with care.

## Using Multiple Accounts Simultaneously

If you need to use metrics with multiple sets of authentication credentials simultaneously, you can do it with `Client`:

```ruby
joe = Librato::Metrics::Client.new
joe.authenticate 'email1', 'api_key1'

mike = Librato::Metrics::Client.new
mike.authenticate 'email2', 'api_key2'
```

All of the same operations you can call directly from `Librato::Metrics` are available per-client:

```ruby
# list Joe's metrics
joe.metrics
```

There are two ways to associate a new queue with a client:

```ruby
# these are functionally equivalent
joe_queue = Librato::Metrics::Queue.new(client: joe)
joe_queue = joe.new_queue
```

Once the queue is associated you can use it normally:

```ruby
joe_queue.add temperature: { value: 65.2, tags: { city: 'san francisco' } }
joe_queue.submit
```

## Thread Safety

The `librato-metrics` gem currently does not do internal locking for thread safety. When used in multi-threaded applications, please add your own [mutexes](http://www.ruby-doc.org/core-2.0/Mutex.html) for sensitive operations.

## More Information

`librato-metrics` is sufficiently complex that not everything can be documented in the README. Additional options are documented regularly in the codebase. You are encouraged to take a quick look through the [source](https://github.com/librato/librato-metrics) for more.

We also maintain a set of [examples of common uses](https://github.com/librato/librato-metrics/tree/master/examples) and appreciate contributions if you have them.

## Contribution

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project and submit a pull request from a feature or bugfix branch.
* Please review our [code conventions](https://github.com/librato/librato-metrics/wiki/Code-Conventions).
* Please include specs. This is important so we don't break your changes unintentionally in a future version.
* Please don't modify the gemspec, Rakefile, version, or changelog. If you do change these files, please isolate a separate commit so we can cherry-pick around it.

## Copyright

Copyright (c) 2011-2017 [Solarwinds, Inc.](http://www.solarwinds.com) See LICENSE for details.
