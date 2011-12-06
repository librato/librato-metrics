Librato Metrics
=======

A convenient Ruby wrapper for the Librato Metrics API.

## Installation

On your shell:

    gem install librato-metrics

Then, in your application or script:

    require 'librato/metrics'

## Quick Start

If you are looking for the quickest possible route to getting a data into Metrics, you only need two lines:

    Librato::Metrics.authenticate 'email', 'api_key'
    Librato::Metrics.save :my_metric => 42

Unspecified metrics will send a *gauge*, but if you need to send a different metric type or include additional properties, simply use a hash for the value:

    Librato::Metrics.send :my_metric => {:type => :counter, :value => 1002, :source => 'myapp'}

While this is all you need to get started, this probably isn't the most performant option for you, so read on...

## Authentication

The metrics gem supports multiple methods of persistence, but by default it communicates directly with the Metrics web API.

Make sure you have an [account for Metrics](https://metrics.librato.com/) and then authenticate with your email and API key (you can find it on your account page):

    Librato::Metrics.authenticate 'email', 'api_key'

## Sending Metrics

Queue up a simple gauge metric named `temperature`:

    metric_set = Librato::Metrics::MetricSet.new
    metric_set.queue :temperature => 32.2

Queue up a gauge (`load`) and a counter (`visits`):

    metric_set.queue :load => 2.2, :visits => {:type => :counter, :value => 400}

Queue up a metric with a source:

    metric_set.queue :cpu => {:source => 'app_1', :value => 92.6}

Send queued metrics:

    metric_set.save

## Contribution

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project and submit a pull request from a feature or bugfix branch.
* Please include specs. This is important so we don't break your changes unintenionally in a future version.
* Please don't modify the Rakefile, version, or history. If you do change these files, please isolate a separate commit so we can cherry-pick around it.

## Copyright

Copyright (c) 2011-2012 [Librato Inc.](http://librato.com) See LICENSE for details.