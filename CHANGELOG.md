# 17.6.0

* Add publishing API method to `PUT` draft content items, to be stored only in draft content-store.

# 17.5.0

* Add ability to pass `n` to some PublishingAPI test helpers to say how many times
  the request should be expected.

# 17.4.0

* Add delete helpers to GdsApi::TestHelpers::Rummager

# 17.3.0

* Deprecate passing `type` to `GdsApi::Router#get_route` and `GdsApi::Router#delete_route`

# 17.2.0

* Add PublishingApi intent endpoints and test helpers.

# 17.1.0

* Add a test helper to stub Rummager's behaviour when queueing is enabled.

# 17.0.1

* Change the order of the ContentAPI `tags` request stubs as the first matching
  stub is used.
* Loosens the live `tags` stub to allow cachebust, as per the draft version.

# 17.0.0

* Change the matching behaviour of ContentAPI test helpers to loosen their
  param requirements.
* Add a `bust_cache` option for the ContentAPI `tags` endpoint.

# 16.5.0

* Add Whitehall and Publisher endpoints for reindexing editions tagged to topics.

# 16.4.0

* Change the Panopticon Registerer adapter to support the `public_timestamp`
  and `latest_change_note` fields.

# 16.3.4

* Update content API test helper `#content_api_has_artefacts_with_a_tag` to
  guard against missing keys

# 16.3.3

* Extend content API test helper `#content_api_has_artefacts_with_a_tag` to
  support options for artefacts.

# 16.3.2

* Update collections API test helpers to reflect reality.

# 16.3.1

* Add test helper method to stub gone route registration.

# 16.3.0

* Add support for registering gone routes with the router.

# 16.2.0

* Add `start` and `total` options to the Collections API test helper.

# 16.1.0

* Allow the `start` and `count` arguments to be provided to the Collections API
  adapter for a sub-topic.

# 16.0.0

* Pass correct parameters to assert_requested in email alert API endpoint helpers.
* Include latest changes in collections API endpoint.

# 15.2.0

* Add Rummager test helpers for adding documents

# 15.1.1
* Change e-mail alert API endpoints

# 15.1.0

* Add panopticon support for `primary_section` and `sections`
* Deprecate support for `section`

# 15.0.0

* Reduce public interface for Email Alert API (unused)

# 14.11.0

* Add support for endpoints to create, update and publish tags in Panopticon

# 14.10.0

* Add email alert API support

# 14.9.0

* Add problem reports endpoint to `support-api`

# 14.8.0

* Add `support-api` endpoint for getting problem report daily totals
* Add Performance Platform endpoint for uploading problem report daily totals

# 14.7.0

* Add long-form contact endpoint to `support-api`

# 14.6.0

* Add extra layer of inheritance for HTTP Exception classes to provide HTTPServerError and HTTPClientError in order to allow applications to to catch ranges of Server/Client type errors.
* Add a helper method, `build_specific_http_error`, in order to handle raising specific error types based on HTTP error codes.

# 14.5.0

* Add `custom_matcher` parameter to panopticon `stub_artefact_registration` to allow partial matching of request body.

# 14.4.2

* Corrects the endpoint for `#collections_api_has_no_curated_lists_for` test helper

# 14.4.1

* Corrects the collections api endpoint for curated lists

# 14.4.0

* Add more content api draft tag functions.

# 14.3.0

* Add "does not have" stubs for content api tags.
* Expand collections api test helpers.

# 14.2.0

* Adds basic collections API client and test helpers

# 14.1.1

* Update the content API sorted tags test helper to support draft mode.

# 14.1.0

* Add rummager test helper for stubbing sub-sector organisations (`rummager_has_specialist_sector_organisations`).

# 14.0.0

* Split content item write API from the content store client into a new publishing API client.

# 13.0.0

* `FinderSchema#user_friendly_values` now returns a hash with the slug version
   of the attribute as the key, with a label and a values Array, which contains
   a label and slug version of each value.

# 12.5.0

* Add test helper for content store being unavailable

# 12.4.2

* Stub "everything including draft" calls for tag test helpers
  even when the helpers themselves aren't setting up draft tags.

# 12.4.1

* Fixes services and info data fixture

# 12.4.0

* Add `rummager_has_no_services_and_info_data_for_organisation`

# 12.3.0

* Add "draft" option to the content_api.tags method.

# 12.2.0

Add .expires_in, .expires_at to GDSApi::Response

These methods expose the expiration time in seconds
and absolute time value respectively, by inferring
them from max-age or expires values received in
response from content store.

# 12.1.0

* Add rummager test helpers

# 12.0.0

* `FinderSchema#user_friendly_facet_value` always returns metadata values as Arrays.

# 11.6.0

* Support the `sort` parameter on the Content API adapter's `tags` and `child_tags` methods.
* Include test for Rummager adapter behaviour  on a response with a 422 status.

# 11.5.0

* Add `support-api` adapter

# 11.4.0

* Improve content-store test helpers

# 11.3.0

* Add `add_document` and `remove_document` methods to Rummager adapter.

# 11.2.0

* Add content-store test assertion helper.

# 11.1.0

* Adds areas_for_type method for Imminence.

# 11.0.0

* BREAKING CHANGE: router client no longer commits by default (see
  https://github.com/alphagov/gds-api-adapters/commit/f7a6f5e for more details).
* Added more test helpers for router client

# 10.17.1

* Bug fix: remove `put_content_item`, we want to be aware of `PUT` failing on content store

# 10.17.0

* Add methods for PUTing data to content-store.

# 10.16.0

* Lookup Mapit areas by postcode via Imminence.

# 10.15.1

* Fix inheritance of content-store client.

# 10.14.0

* Update business support scheme helpers to match API behaviour.

# 10.13.0

* Expose Mapit areas by area type. Adds the method ```areas_for_type(type)```.

# 10.11.2

* Update organisation test helper, adding logo and brand class details to the helper

# 10.11.1

* Add router test helpers

# 10.11.0

* Add Maslow adapter with link builder

# 10.10.1

* Add panopticon artefact registration test helper

# 10.10.0

* Add support for registering multiple need_ids with panopticon

# 10.9.0

* Add support for `PUT` multipart requests
* Add support for replacing assets in asset manager using `PUT`

# 10.8.0

* Data-in API (corporate content problem reports): endpoints for counts, top urls

# 10.7.0

* Include organisation slugs if available when registering artefacts

# 10.6.4

* Add an `artefact!` method to Content API adaptor that can raise exceptions

# 10.6.3

* Added `needs_by_id` method to Need API adaptor for retrieving multiple needs with one request

# 10.6.2

* Data-in API (service feedback): specify which dataset is missing in the exception

# 10.6.1

* Fix bug with default schema factory for finder API

# 10.6.0

* Add more methods to interact with the finder API schema response

# 10.5.0

* Add new unified search endpoint for Rummager adapter

# 10.4.0

* Added method for finder API schema endpoint

# 10.3.0

* Added client for interacting with the GOV.UK [finder API](https://github.com/alphagov/finder-api).
* Added support for array parameters in query strings (eg `foo[]=bar&foo[]=baz`)

# 10.2.0

* Modify test helpers to match changes to `web_url` and `tag_id` in Content API.
* Add test helper for stubbing artefacts with multiple tags.

# 10.1.0

* Added client for interacting with the GOV.UK [external link tracker](https://github.com/alphagov/external-link-tracker).

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

* We've added a unique request ID called `GOVUK-Request-Id` at the varnish layer so that it's easier to trace a request moving through the GOV.UK application stack. This change ensures that all API calls pass on the `GOVUK-Request-Id` header. More details in [README.md](https://github.com/alphagov/gds-api-adapters#middleware-for-request-tracing).

# 8.0.0

* Changes to the Content API adapter to decouple tag methods from the `section` tag type.
* Changes to Content API test helper stub data which may break tests in clients.

# 7.5.1

* Support app: problem report creation happens on `/anonymous_feedback/problem_reports` instead of `/problem_reports`

# 7.3.0

* Integrate Support app API for creating FOI requests

# 7.1.0

* Add Rummager method for `/organisations.json`

# 7.0.0

* Support arbitrary search parameters in `GdsApi::Rummager`

* Remove obsolete format_filter param from `GdsApi::Rummager` methods
* Remove obsolete autocomplete method from `GdsApi::Rummager`

# 6.1.0

* Add Content API method for `/artefacts.json`

# 6.0.0

Potentially backwards-incompatible changes:

* The `disable_timeout` option has been removed.
* `JsonClient` now respects the `Expires` headers when caching results.  If no `Expires` header is set, the global cache TTL will be used (defaults to 15 mins).
* The Rummager client now inherits from `GdsApi::Base`.  This means that it uses `JsonClient` and therefore inherits its timeout and caching behaviour.

Other changes:

* Added Worldwide API client.
