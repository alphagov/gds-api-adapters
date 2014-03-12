# 10.0.0

* Query business support schemes by faceted search parameters e.g. ```locations=scotland,england```. 
* Remove the ability to retrieve by identifiers.

# 9.0.0

* Remove obsolete `curated_lists` method from Panopticon API.

# 8.4.1

* Rename `industry_sectors` attribute to `specialist_sectors` to match Panopticon

# 8.4.0

* Add deep-link to anonymous feedback in Feedex.

# 8.3.2

* Update to a more sensible Performance Platform DataIn service feedback endpoint.

# 8.3.1

* Bugfix to constructing the Performance Platform DataIn service feedback endpoint.

# 8.3.0

* Add the Performance Platform DataIn service feedback endpoint, for uploading service feedback aggregated stats.

# 8.2.3

* Allow the `industry_sectors` attribute to be provided to the Panopticon registerer.

* New Content API test helper added for stubbing `with_tag.json` request with a custom sort order.
* The Content API tag tests now use test helpers to stub endpoints.
* Removed the `include_children` parameter from Content API adapters, which was removed from the Content API in April '13.
* Fix for the `content_api_has_artefacts_with_a_tag` helper to not expect query string parameters in an order when stubbing URLs.
* Fix for a typo in a test helper.

# 8.2.2

* Changes the test helpers for stubbing out Content API requests for artefacts with section tags so that they work for any tag type.

# 8.2.1

* Fix a bug where `gds_api/govuk_request_id.rb` would fail to load if the `GdsApi` module was not already defined.

# 8.2.0

* Add a method to re-open closed needs in the need API.

# 8.1.0

* We've added a unique request ID called `GOVUK-Request-Id` at the varnish layer so that it's easier to trace a request moving through the GOVUK application stack. This change ensures that all api calls pass on the GOVUK-Request-Id header. More details in [README.md](https://github.com/alphagov/gds-api-adapters#middleware-for-request-tracing).

# 8.0.0

* Changes to the Content API adapter to decouple tag methods from the `section` tag type.
* Changes to Content API test helper stub data which may break tests in clients.

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
