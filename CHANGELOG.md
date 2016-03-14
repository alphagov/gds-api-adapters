* Add `GdsApi::PublishingApiV2#lookup_content_id` and `GdsApi::PublishingApiV2#lookup_content_id`

# 29.5.0

* Add `GdsApi::HTTPUnprocessableEntity` to represent a 422 error

# 29.4.0

* Support searching by a `document_type` in email-alert-api

# 29.3.1

* Fix linkables test helper.

# 29.3.0

* Prefer `document_type` as the arg for `get_linkables`, deprecating `format`.

# 29.2.0

* Enable Draft Content Store testing in test helpers.

# 29.1.1

* Fix publishing API `patch_links` test helpers.

# 29.1.0

* Add code and pact tests for the new publishing API `GET /v2/linkables` endpoint.

# 29.0.0

* Breaking change: rename `PublishingApiV2`'s `put_links` to `patch_links` to
  better reflect the behaviour. Also rename related test_helper methods.

# 28.3.1

* Fixed `TestHelpers::Imminence` missing `end`.

# 28.3.0

* `TestHelpers::Imminence` now has `imminence_has_places_for_postcode` and
  `stub_imminence_places_request` helper methods. There was previously no helper
  for the find places with post code tools. It is now possible to stub all requests
  for places with any status code or payload as required.

# 28.2.1

* `TestHelpers::PublishingApiV2` now has a `publishing_api_does_not_have_links` test helper
  which stubs the Publishing API V2 to return the 404 payload for the `content_id` passed
  as the arg.

# 28.2.0

* Pass the Govuk-Original-Url header on to requests made by gds-api-adapters,
  similarly to the existing Govuk-Request-Id header.  Rails applications will
  get this support automatically when using this version of gds-api-adapters.
  Other applications will need to add an explicit call to `use
  GdsApi::GovukHeaderSniffer, 'HTTP_GOVUK_ORIGINAL_URL"`, as detailed in the
  README.

# 28.1.1

* `TestHelpers::PublishingApiV2` now has a `publishing_api_does_not_have_item` test helper
  which stubs the Publishing API V2 to return the 404 payload for the `content_id` passed
  as the arg.

# 28.1.0

* Add `PublishingApiV2#get_content!`

# 28.0.2

* `TestHelpers::PublishingApiV2` now has a `publishing_api_has_links` test helper
  which stubs the Publishing API V2 to return the links payload which is supplied
  as the arg.

# 28.0.1

* In `TestHelpers::PublishingApiV2` - for methods that accept an optional arg
  `attributes_or_matcher`, change the default value to nil so that we don't test
  for request body if the argument is not supplied.
* In the same class, fix `#publishing_api_has_fields_for_format` so that we
  always cast the `item` arg to Array. This correctly handles cases where only
  one item is passed in.

# 28.0.0

* Drop support for Ruby 1.9.3
* Raise `HTTPUnauthorized` for 401 responses

# 27.2.2

* Fix `ContentStore#incoming_links`.

# 27.2.1

* `PublishingAPIV2`: prevent clients from using nil `content_id` values

# 27.2.0

* Add some useful test helpers for EmailAlertApi

# 27.1.1

* Pin Plek to >= 1.9.0 because gds-api-adapters depends on Plek.find

# 27.1.0

* Add Plek service discovery for EmailAlertApi test helpers

# 27.0.0

* Fix issue within `PublishingApiV2` test helpers where
  `request_json_matching` and `request_json_including` were incorrectly
  named and had the opposite behaviour.
* The default behaviour of `assert_publishing_api` (and the more specific
  helpers that use it) is not to match the entire supplied attributes.
  To do partial matching use `request_json_includes`
* Add support for symbol keys to the `PubishingApiV2` test helpers.

# 26.7.0

* Add support for Rummager's `delete_content` & `get_content`.

# 26.6.0

* Add `PublishingApiV2#get_linked_items`.

# 26.5.0

* Changed SpecialRoutePublisher to use v2 of publishing-api

# 26.4.0

* Performance Platform: add test helper stub for non-existent datasets
* Add `ContentStore#incoming_links!`

# 26.3.1

* Fix the composite "put and publish" Publishing API v2 stub

# 26.3.0

* Publishing API v2: add stub for 404 responses

# 26.2.0

* Support optional locale and previous version for discard_draft publishing API call

# 26.1.0

* Add publishing api discard draft endpoint

# 26.0.0

* Flesh out and rename methods in Publishing API v2 test helpers

# 25.3.0

* Add Test Helpers for Publishing API V2 `index` and `get`

# 25.2.0

* Add `PublishingApiV2#get_content_items`.

# 25.1.0

* Add support for optimistic locking to the v2 publishing API endpoints.

# 25.0.0

* Allow `Mapit#location_for_postcode` to raise if it receives something which doesn't look like a postcode.

# 24.8.0

* Add test helpers for Publishing-API path reservation endpoint

# 24.7.0

* Add put_path endpoint for Publishing-API

# 24.6.0

* Support segments_mode option for add_redirect_route.

# 24.5.0

* Adds the helper methods and pact tests for the GET and PUT publishing API endpoints for managing links
  independently of content items.

# 24.4.0

* Set the connection timeout in RestClient as well as the read timeout

# 24.3.0

* Raise `HTTPConflict` exception for HTTP 409 status codes.

# 24.2.0

* Change the Panopticon Registerer adapter to support the `content_id` field.

# 24.1.0

* Add test helper `content_register_isnt_available`

# 24.0.0

* Remove support for the `/organisations` endpoint on Rummager.

# 23.2.2

* Bugfix: `SpecialRoutePublisher` handles case where `Time.zone` returns `nil`

# 23.2.1

* Bugfix: remove invalid require from GdsApi::Helpers

# 23.2.0

* Add special route publisher under PublishingApi.

  This is be used in several apps for registering
  "special" routes like /government or /robots.txt

  See https://trello.com/c/blLdEZN5/292-make-apps-register-special-routes-on-deploy

# 23.1.0

* GdsApi::TestHelpers::PublishingApi

  added the ability to make more flexible assertions about publishing api
  requests by optionally passing a predicate to the assertions. The
  `request_json_including` predicate will match required elements of a hash or
  a nested hash in the JSON body.

  The existing stricter behaviour is retained as the default
  (`request_json_matching` predicate).

# 23.0.0

* Remove `GdsApi::Rummager#search`. The `/search` endpoint was removed
  from rummager in favor of `/unified_search`.

# 22.0.0

* Remove `FinderAPI` and `FinderSchema` classes.
  Finder API has been retired and these are no longer used.

* Raise specific error on 404 in content-store client.

# 21.0.0

* Using GdsApi::ContentApi#tag without the second parameter for tag type will
raise an error.

# 20.1.2

* Fix content-store test stubs key type
* Fix GdsApi::Response `method_missing` signature

# 20.1.1

* Fix stray collections-api require

# 20.1.0

* Change the user agent string to include the app name, eg:
  `GDS Api Client v. 20.1.0` -> `gds-api-adapters/20.1.0 (whitehall)`

# 20.0.0

* remove collections-api client and helpers.
  The application has been retired.

* Don't cache Cache-Control "private" and "no-store" responses.

* Update content_store_has_item test helper to support better overriding of
  Cache-Control headers in responses.

# 19.2.0

* Raise HTTPForbidden on a 403 response.

# 19.1.0

* Pass HTTP_X_GOVUK_AUTHENTICATED_USER in API requests.

# 19.0.0

* Remove old policy test helpers for rummager.

# 18.11.0

* Add support for organisation list and show in Support API

# 18.10.0

* Add support for exporting CSVs from the Support API

# 18.9.1

* Fix a bug in the SupportApi test helper for organisations_list

# 18.9.0

* Support API: add adapters for `/anonymous-feedback/organisations` list, and
  `/anonymous-feedback/organisations/:slug` feedback summary endpoints.

# 18.8.0

* Support API: add adapter for `/anonymous-feedback` feed endpoint

# 18.7.0

* Change name of Rummager policy-tagging test helpers to reflect the fact that
  they stub for any type.  Deprecates the old helpers.

# 18.6.0

* Change Rummager test helpers to allow stubbing specific counts for requests
  for policies for an organisation.

# 18.5.0

* Add Rummager test helpers to stub requests for policies for an organisation.

# 18.4.0

* Make TestHelpers::Organisations more flexible

# 18.3.1

* Fix `content_api_has_artefacts_with_a_tag` test helper

# 18.3.0

* Add assert_publishing_api_put_draft_item to publishing_api_helpers
* Bump rest-client for security fixes

# 18.2.0

* Remove base_path from publishing_api content_item_helpers.
* Add helper to stub draft publishing API default.

# 18.1.0

* Adds support for the PUT endpoint of content register
* Test helpers for the `GdsApi::ContentRegister` adapter

# 18.0.0

* Update rest-client dependency for security fixes: https://github.com/rest-client/rest-client/commit/221e3f200f76bd1499591fbc6c3ea3f6183b66ef
* Publishing API test helpers responses no longer include the entities
* Government API test helpers responses include the content_id

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
