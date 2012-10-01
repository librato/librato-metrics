## Changelog

### Version 0.7.1
* Add prefix option to Queues

### Version 0.7.0
* Add ability to update metric properties (Christoph Bünte)
* Add ability to merge queue and aggregator data into a queue
* Aggregator supports custom source by measurement
* Add option to clear queued measurements after failed submit
* Custom user agent support
* Documentation improvements

### Version 0.6.1
* Loosen restrictions to older versions of faraday and multi_json
* Fix symbol casting issue in jruby with metric delete
* client#new_queue now respects passed options
* Queue objects support default source properly

### Version 0.6.0
* Add Aggregator class for aggregating measurements client-side
* Queue and Aggregator can auto-submit on a time interval
* Queue can auto-submit on a specified volume of measurements
* Support deleting individual metrics
* Validate user-specified measurement times
* Update to MultiJSON 1.3 syntax
* Run tests for rubinius and jruby in both 1.8 and 1.9 modes
* Include request body in output for failed requests
* Documentation improvements

### Version 0.5.0
* Support using multiple accounts simultaneously via Client
* Switch network library to faraday for broader platform support and flexibility
* Automatically break large submissions into multiple requests for better performance
* Automatic retry support
* Consolidate connection functions in Connection
* Documentation improvements

### Version 0.4.3
* Bump excon to 0.13x to fix proxy support

### Version 0.4.2
* Fix SSL verify peer issues with JRuby (Sean Porter)

### Version 0.4.1
* Fix issues with auth encoding whitespace

### Version 0.4.0
* Add ability to set agent_identifier for use with developer program (Sean Porter)
* Documentation improvements

### Version 0.3.1
* Upgrade excon to 0.9.5 to fix intermittent socket errors

### Version 0.3.0
* Add auto-pagination support to metric listing (Nuno Valente)
* Add #size/#length to Queue objects (Michael Gorsuch)
* Add #empty? to Queue objects
* Remove deprecated .json extensions from API URIs
* Use new singular route for metric GETs
* README improvements
* Add #clear as alias to Queue's #flush
* Switch to multi_json for better cross-platform json handling
* Set up basic integration testing suite
* Improve testing rake tasks

### Version 0.2.3
* Fix broken user-agent string in 1.8.7 (Sean Porter)
* Update outdated spec

### Version 0.2.2
* Fix abstract persistence instantiation in Ruby 1.8/REE

### Version 0.2.1
* Add better handling for start_time and end_time params when fetching measurements

### Version 0.2.0
* Fix bug with stale excon connections not reconnecting
* Add custom User-Agent
* Items added to Queue objects have their measure_time set automatically
* Metric 'type' key can be string or symbol (Neil Mock)

### Version 0.1.0
* Initial release