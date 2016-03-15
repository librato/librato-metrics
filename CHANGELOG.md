## Changelog

### Version 1.6.1
* Fix bugs with listing sources (#116)

### Version 1.6.0
* Add HTTP proxy support (#112) (Genki Sugawara)

### Version 1.5.1
* Fix bug causing incompatible dates when annotating with block form (#109)

### Version 1.5.0
* Add #get_composite for easier fetching of composite measurements

### Version 1.4.0
* Add support for snapshots

### Version 1.3.2
* Fix queue autosubmission to fire if needed after #merge! calls

### Version 1.3.1
* Fix auto-chunking for large measurements sets with a global source

### Version 1.3.0
* Add support for working with sources as a first-class entity

### Version 1.2.0
* Give metric-facing methods more explicit names & deprecate priors
* Documentation improvements

### Version 1.1.1
* Move gem sign code to rake task, fixes bug bundling in some environments

### Version 1.1.0
* Add ability to update annotation events
* Add ability to fetch annotation events
* Add block form of annotation
* Add metric batch update support
* Add support for pattern-based metric deletes
* Add set of code examples
* Sign gem when building
* Documentation improvements

### Version 1.0.4
* Ensure sane default timeouts for all requests

### Version 1.0.3
* Fix bug where retries of POST requests could 400
* Network related exceptions capture response state better

### Version 1.0.2
* Fix bug with some versions of MultiJson (Thomas Dippel)
* Use delegation for JSON handling
* Improve integration tests

### Version 1.0.1
* Fix Forwardable dependency loading bug

### Version 1.0.0
* Add support for annotation submission, listing, management
* Auto-convert Time objects anywhere a time is accepted
* Don't raise exception anymore for empty queue submission

### Version 0.7.5
* Catch a broader range of connection failures for retrying
* Add Metrics.faraday_adapter config option (Mathieu Ravaux)

### Version 0.7.4
* Support global measure_time option for Queues/Aggregators
* Support all versions of multi_json so we can relax version constraint

### Version 0.7.3
* Allow prefixes to be changed after instantiation on Queues/Aggregators

### Version 0.7.2
* Extend prefix option support to Aggregators

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