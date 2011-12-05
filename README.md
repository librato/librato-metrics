Librato Metrics
=======

A convenient Ruby wrapper for the Librato Metrics API.

## Installation

    gem install librato-metrics

## Standard Usage

Set up your credentials:

    Librato::Metrics.authenticate 'username', 'api_key'

Queue up a simple gauge metric named `temperature`:

    metric_set = Librato::Metrics::MetricSet.new
    metric_set.queue :temperature => 32.2

Queue up a gauge (`load`) and a counter (`visits`):

    metric_set.queue :load => 2.2, :visits => {:type => :counter, :value => 400}

Queue up a metric with a source:

    metric_set.queue :cpu => {:source => 'app_1', :value => 92.6}

Send queued metrics:

    metric_set.send

## Contribution

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project and submit a pull request from a feature or bugfix branch.
* Please include specs. This is important so we don't break your changes unintenionally in a future version.
* Please don't modify the Rakefile, version, or history. If you do change these files, please isolate a separate commit so we can cherry-pick around it.

## Copyright

Copyright (c) 2011-2012 [Librato Inc.](http://librato.com) See LICENSE for details.