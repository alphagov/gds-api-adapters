# 6.0.0 (unreleased)

Potentially backwards-incompatible changes:

* The `disable_timeout` option has been removed.
* `JsonClient` now respects the Expires headers when caching results.  If no Expires header is set, the global cache ttl will be used (defaults to 15 mins).
* The Rummager client now inherits from `GdsApi::Base`.  This means that it uses `JsonClient` and therefore inherits its timeout and caching behaviour.

Other changes:

* Added Worldwide API client.
