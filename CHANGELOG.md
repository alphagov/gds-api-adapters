# 7.5.1

* Support app: problem report creation happens on /anonymous_feedback/problem_reports instead of /problem_reports

# 7.3.0

* Integrate Support app API for creating FOI requests

# 7.1.0

* Add Rummager method for /organisations.json

# 7.0.0

* Support arbitrary search parameters in GdsApi::Rummager

* Remove obsolete format_filter param from GdsApi::Rummager methods
* Remove obsolete autocomplete method from GdsApi::Rummager

# 6.1.0

* Add ContentAPI method for /artefacts.json

# 6.0.0

Potentially backwards-incompatible changes:

* The `disable_timeout` option has been removed.
* `JsonClient` now respects the Expires headers when caching results.  If no Expires header is set, the global cache ttl will be used (defaults to 15 mins).
* The Rummager client now inherits from `GdsApi::Base`.  This means that it uses `JsonClient` and therefore inherits its timeout and caching behaviour.

Other changes:

* Added Worldwide API client.
