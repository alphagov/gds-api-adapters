# Unreleased

* Renames the Email Alert API `send_alert` method to `create_content_change` (and
  related test helper methods) to reflect a change in the underling endpoint.
  **Note:** this is a breaking change for users of the Email Alert API
  adapters.
* Adds `create_email` Email Alert API method to send individual emails.

# 59.6.0

* Adds content_id to worldwide location test helper
* Adds middleware to allow the header `X-Govuk-Authenticated-User-Organisation`
  to be passed along to content-store.
* Changes logging level about header forwarding from info to debug

# 59.5.1

* Adds `combine_mode` parameter to Email Alert API test helpers

# 59.5.0

* Adds `combine_mode` parameter to Email Alert API `find_subscriber_list` method

# 59.4.0

* Adds `stub_email_alert_api_has_subscriptions` test helper method.
* Ensures that `stub_email_alert_api_has_subscription` also stubs the `/latest` endpoint.

# 59.3.0

* Add `get_latest_matching_subscription` method to `GdsApi::EmailAlertApi`.

# 59.2.1

* Warn when `GdsApi::Rummager` is initialised and `GdsApi::TestHelpersRummager`
  is included.

# 59.2.0

* Add `GdsApi::Search`, deprecate `GdsApi::Rummager`.
* Add `GdsApI::TestHelpers::Search`, deprecate `GdsApi::TestHelpers::Rummager`.
* Make `GdsApi.search` return a `GdsApi::Search`, deprecate `GdsApi.rummager`.

# 59.1.0

* Use `POST` rather than `GET` to perform anonymous feedback queries with
  support-api.

# 59.0.0

* Expect applications to access the bank holidays API via the public website
  and not internally via the calendars app.

# 58.0.0

* Rename references of subscribable to subscriber_list in Email Alert API. Note
  this is a breaking change for users of the Email Alert API adapters, clients
  will need to also update any references to subscribable.

# 57.5.0

* Support new unreserve_path endpoint for Publishing API (v1) adapter
* Remove reject_content_purpose_supergroup as optional email alert api subscriber list param

# 57.4.2

* Find rummager by using the "search" alias, rather than referring to "rummager" directly

# 57.4.1

* Add reject_content_purpose_supergroup as optional email alert api subscriber list param

# 57.4.0

* Add GdsApi::PublishingApiV2#republish endpoint to `publishing_api`

# 57.3.1

* Rename `create_business_finder_feedback` to `create_content_improvement_feedback`

# 57.3.0

* Add Router API stubs for getting routes.

# 57.2.4

* Add `content_purpose_supergroup` as optional parameter to `find_subscriber_list` in `GdsApi::EmailAlertApi`
* Add automatic bearer tokens for `GdsApi.router` and `GdsApi.content_store`.

# 57.2.3

* Add `create_business_finder_feedback` to `GdsApi::SupportApi`
* Add `stub_support_api_create_business_finder_feedback` to `GdsApi::TestHelpers::SupportApi`

# 57.2.2

* Fix more deprecated helpers (Asset Manager and Link Checker API)
* Fix stub_asset_manager_receives_an_asset not returning unique filenames each call
* Rename stub_asset_manager_is_down to stub_asset_manager_isnt_available

# 57.2.1

* Fix broken test helper for Publishing API

# 57.2.0

* Change all test helpers to use a stub\_ prefix (old names are now aliases)

# 57.1.0

* Add additional Asset Manager test helper methods

# 57.0.0

* Pass `LINK_CHECKER_API_BEARER_TOKEN` in Link Checker API requests if present.
* Pass `SUPPORT_API_BEARER_TOKEN` in Support API requests if present.

# 56.0.0

* Change the expected Publishing API behaviour regarding percent-encoding of URLs included in responses.
* Remove many deprecated methods
  - `GdsApi::TestHelpers::Rummager.stub_any_rummager_post_with_queueing_enabled`
    - Use `stub_any_rummager_post` instead
  - `GdsApi::Rummager.delete_content!` and `GdsApi::Rummager.get_content!`
     - Use `delete_content` and `get_content` respectively
  - `GdsApi::PublishingApiV2.get_content!`
     - Use `get_content` instead
  - `GdsApi::PublishingApi.put_path`
     - Use `GdsApi::PublishingApiV2.put_path` instead
  - `GdsApi::ContentStore.get_content!`
     - Use `get_content` instead
* Remove the `type` parameter from `GdsApi::Router.get_route`
* Remove the `GdsApi::Helpers` module
  - Use the `GdsApi` module methods instead

# 55.0.2

* Add SocketError exception handling.

# 55.0.1

* Change how the default logger is assigned.

# 55.0.0

* Ensure new Publishing API patch_links stub is symbol/string-agnostic
* Change GdsApi.organisations adapter to use the public organisations API
* Fix the URL for Rummager batch queries.

# 54.1.3

* Extend Publishing API V2 unavailable stub to cover legacy V1 routes
* Extend Asset Manager not found stub to cover delete action

# 54.1.1

* Add extra Publishing API stub for conflict when patching links

# 54.1.0

* Add ability to batch search Rummager

# 54.0.0

* Expect `GdsApi::TestHelpers::Organisations` to be using the public API instead of Whitehall.

# 53.2.0

* Add methods to GdsApi to create instances of adapters with common options to reduce boilerplate code across apps
* Deprecate GdsApi::Helpers in favour of using explicit GdsApi.service_name methods

# 53.1.0

* Add Asset Manager test helpers: `asset_manager_update_asset`, `asset_manager_update_failure`, `asset_manager_delete_asset` and `asset_manager_delete_asset_failure`.

# 53.0.0

* Remove support for caching responses.

# 52.8.0

* Add support for the `unpublish-messages` endpoint in email-alert-api

# 52.7.0

* Expose the `country_name` parameter as part of the Mapit test helper
* Add `put_path` method to PublishingApiV2

# 52.6.0

* Add `generate` argument to `publishing_api_has_expanded_links` which reflects the behaviour of the actual request
  more closely

# 52.5.1

* Make the subscription response for Email Alert API closer to reality.

# 52.5.0

* Add `create_auth_token` to `GdsApi::EmailAlertApi`.

# 52.4.0

* Add `unsubscribe_subscriber` to `GdsApi::EmailAlertApi`.

# 52.3.0

* Change `get_subscriptions` and `change_subscriber` to accept a subscriber ID rather than an email address

# 52.2.1

* Add a title parameter to the `get_subscription_response` stub for Email Alert API.

# 52.2.0

* Add `get_subscription`, `get_subscriptions`, `change_subscriber` and `change_subscription` to `GdsApi::EmailAlertApi`.

# 52.1.0

* Add `GdsApi::HTTPIntermittentServerError` and `GdsApi::HTTPIntermittentClientError` superclasses.
* Add a `GdsApi::HTTPTooManyRequests` exception

# 52.0.0

* Remove deprecated `notifications` and `notification` methods from `GdsApi::EmailAlertApi`.

# 51.4.0

* Add support for the /feedback-by-day endpoint in the Support API

# 51.3.0

* Add `locale` param to `get_expanded_links` in the Publishing API
  client

# 51.2.0

* Add helper method `.redirect_for_path` to GdsApi::ContentStore to allow determining a redirect destination from a request

# 51.1.1

* Add frequency param to `assert_subscribed` in Email alert api test helpers

# 51.1.0

* Include frequency as a parameter when subscribing to emails through Email alert api

# 51.0.0

* **Breaking Change:** Require a minimum of Ruby 2.3
* Change name of `DISABLE_JSON_API_CACHE` environment variable to `GDS_API_DISABLE_CACHE`

# 50.9.1

* Percent encode URLs when requesting Whitehall assets from Asset Manager API

# 50.9.0

* Add Environment variable which can disable caching of JSON API requests, `DISABLE_JSON_API_CACHE`

# 50.8.0

* Add V2 api endpoints for GdsAPI::Rummager#delete_document
* Add V2 api endpoints for GdsAPI::Rummager#insert_document

# 50.7.0

* Add GdsApi::SupportApi#document_type_list to retrieve list of formats for content items
* Add GdsApi::SupportApi#document_type_summary to retrieve feedback associated with content items of a certain format.

# 50.6.0

* Add `with_drafts` optional parameter to GdsApi::PublishingApiV2#lookup_content_ids and GdsApi::PublishingApiV2#lookup_content_id

# 50.5.0

* Add #email_alert_api_refuses_to_create_subscription test helper for
  email-alert-api to simulate an error condition when trying to create
  a subscription.

# 50.4.0

* Add GdsApi::EmailAlertApi#get_subscribable to retrieve subscribable
  (currently SubscriberList in the api) by `gov_delivery_id`
  (called `reference:` here as we will be renaming it in the API)

# 50.3.0

* Add GdsApi::PublishingApiV2#get_content_items_enum to enumerate content items

# 50.2.0

* Add GdsApi::EmailAlertApi#subscribe to allow users to subscribe to emails

# 50.1.0

* Add GdsApi::EmailAlertApi#unsubscribe to allow users to unsubscribe from emails.

# 50.0.0

* Remove GdsApi::NeedApi
* Change GdsApi::Router.delete\_route to take an optional hard\_delete
  argument, removing support for the deprecated type argument.

# 49.8.0
* Add GdsApi::Rummager#search_enum method to expose search results as an enumerator.

# 49.7.0

* Add GdsApi::LinkCheckerApi#upsert_resource_monitor method for creating/updating a collection of monitored links for an application.

# 49.6.0

* Add GdsApi::AssetManager#whitehall_asset method for retrieving Whitehall assets from Asset Manager.

# 49.5.0

* Allow rummager search to pass additional headers

# 49.4.0

* Document new optional `legacy_etag` & `legacy_last_modified` attributes that
can be passed into `GdsApi::AssetManager#create_whitehall_asset` within the
`asset` Hash (#760)

# 49.3.1

* Avoid the following warning: Overriding "Content-Type" header "application/json" with "multipart/form-data; boundary=----RubyFormBoundaryX7Na6WDQqG3kLfD7" due to payload

# 49.3.0

* Use 1.5.0 minimum of [govuk-content-schema-test-helpers](https://github.com/alphagov/govuk-content-schema-test-helpers)
* Remove gem_publisher dependency since rake task is no longer used to publish gem

# 49.2.0

* Add GdsApi::AssetManager#create_whitehall_asset method (#752)

# 49.1.0

* Remove trailing slash in call to get_link_changes

# 49.0.0

* Remove `GdsApi::GovUkDelivery` and helpers as `govuk-delivery` has been
retired in favour of `email-alert-api`
* Add get_link_changes endpoint for publishing-api

# 48.0.0

* Resurrect `feedback_url` for Support (removed in 46.0.0)
* Remove need-api helper
  Need API is being retired

# 47.9.1

* Group Sentry errors by exception type

# 47.9.0

* Add the HTTPPayloadTooLarge exception

* Add `get_links_for_content_ids` endpoint to Publishing API

* Add more specific exceptions for HTTPInternalServerError (500), HTTPBadGateway (502), HTTPUnavailable (503), HTTPGatewayTimeout (504) exceptions.

# 47.8.0

* Add `email_alert_api.topic_matches`

# 47.7.0

* Separate `find_or_create_subscriber_list` so that individual `find` or
  `create` methods can be called in email-alert-api.

# 47.6.0

* Add `generate` option for Publishing API expanded links endpoint

# 47.5.0

* Add `enable_list` and `disable_list` endpoints for govuk-delivery.

# 47.4.0

* Add a `get_paged_editions` endpoint, which returns a lazy enumerator that pages
  through results from the editions endpoint.

# 47.3.0

* Update `publishing-api` class to support the new get editions endpoint.

# 47.2.1

* Send the update_type of special routes on put content rather than publish.

# 47.2.0

* Make passing the `update_type` to the Publishing API on a publish optional.

# 47.1.3

* Fix Publishing API lookup_content_id and lookup_content_ids to send
  exclude_unpublishing_types rather than exclude_publishing_types.

# 47.1.2

* Pass exclude_document_types and exclude_publishing_types fields to to pubslishing APi
  when calling `lookup_content_id`

# 47.1.1

* Fixes url used for fetching search metrics from `backdrop read API`

# 47.1.0

* Update `link-checker-api` class to support new message format.

# 47.0.0

* Remove support for `content-api`
* Add `HTTPUnprocessableEntity` exceptions
* Introduce 4 new endpoints for `backdrop read API` to be used by `info-frontend`.

# 46.0.0

* Drop dead endpoints from support adapter
* Rename test helpers for support-api to make it clearer they stub requests to support-api
* Delete methods no longer needed by `licence-finder`: `licences_for_ids`,
  `content_api_licence_hash`, `setup_content_api_licences_stubs` and
  `content_api_has_licence`.

# 45.0.0

* Add api adapter for the bank-holidays json provided by calendars

# 44.0.0

* Revert changes made to `update_type` in the Publishing API pact tests in release 43.0.0
* Remove support for the `business-support-api`

# 43.0.0

* Set the `update_type` to major in all of the Publishing API pact tests.
* Remove support for `business_support_schemes`
* Support custom schemas in the SpecialRoutePublisher

# 42.0.0

* Make `lgil` mandatory when requesting links from Local Links Manager

# 41.5.0

* Add missing `link-checker-api` test helpers from the previous release.

# 41.4.0

* Add support for the secure webhooks of the `link-checker-api`.

# 41.3.0

* Add support for the `link-checker-api`.

# 41.2.0

* Update webmock gem dependency
* Add new `locale` and `details` fields to special routes

# 41.1.0

* Add new fields to 'find_or_create_subscriber_list' to support whitehall migration
  - email_document_supertype
  - government_document_supertype
  - gov_delivery_id
* Port all jenkins.sh steps to Jenkinsfile

# 41.0.0

* Rename GOVUK_FACT_CHECK_ID header to GOVUK_AUTH_BYPASS_ID header

# 40.5.0

* Add support to request expanded links from publishing api with or without drafts
  - The default is false, for backward compatibility
  - https://github.com/alphagov/gds-api-adapters/pull/676
  - https://github.com/alphagov/publishing-api/blob/master/doc/api.md#query-string-parameters-2

# 40.4.0

* Add support for a customized `document_type` when publishing a special route,
  but keep the default `document_type` of `special_route`.

# 40.3.0

* Allow headers to be passed into `EmailAlertApi.send_alert`. This change is
  needed to pass the `govuk_request_id` when email alert service processes
  messages off rabbit mq.
* Comment out pact broker jenkins tasks as the service is currently offline. This
  change will be reverted once pact broker is working again.

# 40.2.0

* Add support for passing logging parameters through to Gov Uk Delivery.

# 40.1.0

* Add a redirects option to the Unpublish adapter in Publishing API

# 40.0.0

* Remove Panopticon API
* Include the files within the test/fixtures directory, this fixes
  some test helpers that would have been broken since 39.0.0.

# 39.2.0

* Add support for the import endpoint for the Publishing API.
* The `publishing_api_has_item` test helper can now take a hash of
  params to match the request against.
* Remove Rails specific features from the implementation of some
  Publishing API test helpers.

# 39.1.0

* Pass through GOVUK_FACT_CHECK_ID header. This will be added by
  authenticating-proxy when a draft item is requested with a valid JWT token;
  the value itself will be checked by content-store against the value stored
  in the content item.

# 39.0.0

* Remove the `need_api_has_organisations` test helper.

# 38.1.0

* Handle URI::InvalidURIError exceptions with GdsApi::InvalidUrl
* Removed tests for the deprecated `format` field in the Publishing API.

# 38.0.0

* Added an adapter for the import endpoint of the Need API.
* Removed `GdsApi::Publisher`
* Removed `GdsApi::ExternalLinkTracker`
* Removed deprecated `PublishingApi` endpoints (`put_content_item` and
  `put_draft_content_item`).
* Removed `ContentStore#incoming_links!`
* Removed `ContentStore#content_item!`
* Removed `PublishingApiV2#get_content!`
* Renamed `Rummager#delete_content!` to `Rummager#delete_content`
* Renamed `Rummager#get_content!` to `Rummager#get_content`

# 37.5.1

* Allow #dig on Response.

# 37.5.0

* Support `unpublished_at` field for `PublishingApiV2#unpublish`

# 37.4.0

* Add test helper methods to stub any unpublish or discard draft requests to
  Publishing API V2.

# 37.3.0

* Add a helper method for extracting service feedback from the performance
  platform.

# 37.2.0

* Add test helper method `publishing_api_has_linked_items` for the Publishing
  API V2 method `get_linked_items`.

# 37.1.0

* Add `restore_asset` method to allow the restoration of deleted assets.

# 37.0.0

* Default `always_raise_for_not_found` to true when not configured and add
  deprecation warning for when a client app uses the setter to change the value.
  From December 1st, 2016 it won't be possible to configure this option anymore
  and therefore all responses will raise a `GdsApi::HTTPNotFound` for 404s and
  `GdsApi::HTTPGone` for 410s;
* Default `hash_response_for_requests` to true when not configured and add
  deprecation warning for when a client app uses the setter to change the value.
  From December 1st, 2016 it won't be possible to configure this option anymore
  and therefore all responses will behave like a `Hash` instead of an
  `OpenStruct`;
* Add helper methods to stub and assert Rummager searches;
* Stop using `content_format` in the Publishing API tests;
* Documentation added to `get_content_items`;
* Ruby version upgraded to `2.3.1`;
* Added `govuk-lint` to the project.

# 36.4.1

* Fix bug where the total number of pages was being calculated incorrectly on
  `publishing_api_has_content`;
* Return only the expected items based on the pagination parameters on
  `publishing_api_has_content`.

# 36.4.0

* Remove search-related fields from Panopticon Registerer now that these fields
  are no longer sent by client apps.

# 36.3.0

* Add a support-api endpoint for creating 'Page Improvements'.

# 36.2.0

* Add delete_asset method, to support the new delete asset functionality now supported by asset manager.
* Fix issue where rspec style matchers would cause issues, since they do not implement the fetch method.

# 36.1.0

* Add helpers for the support-api for fetching problem reports and
  for marking problem reports as spam.

# 36.0.1

* Add option to return results as a hash in `GdsApi::ListResponse`.

# 36.0.0

* Remove `GdsApi::Rummager#unified_search`. The `/unified_search` endpoint
  has been removed in rummager in favor of `/search`.
  **This is a breaking change**, which means applications currently using
  `#unified_search` need to migrate to `#search`.

# 35.0.1

* Fix issue where Pact would hit the Publishing API in development if the
  service was running on the same port `3093`;
* Return pagination information from `publishing_api_has_content` in order to
  reflect what would happen in a real request.

# 35.0.0

* Remove methods for `with_tag` endpoint for content api. These methods are not
  used by any client. The endpoint is scheduled to be removed soon.
* Add test helper for Gone items in content store

# 34.1.0

* Deprecate `GdsApi::Rummager#unified_search`. The `/unified_search` endpoint
  has been deprecated in rummager in favor of `/search`.

# 34.0.0

* De-deprecate `delete_document` helpers, because the endpoint is still useful.
* Allow `/document/` helpers to take an optional index parameter, mirroring the API.
* Allow all assert methods to pass through additional webmock options
* Change `stub_any_rummager_post` to behave the same as
  `stub_any_rummager_post_with_queueing_enabled`: rummager always returns 202 and
  so should our stubs.
* Deprecate `stub_any_rummager_post_with_queueing_enabled` as it is now redundant.

# 33.2.2

* Fix JsonClient not explicitly requiring the config

# 33.2.1

* Send correct headers for GET and DELETE requests.
* Extend option to always raise for 404 and 410 to `get_raw`.

# 33.2.0

* Update RestClient version to 2.0.0

# 33.1.0

* Add support-api global export endpoint

# 33.0.0

* Simplify state name presentation (live to published)

# 32.3.0

* Add option to always raise for 404 and 410.
* Add option to make `GdsApi::Response` just behave like a hash, not an OpenStruct
* Add local links manager local authority endpoint

# 32.2.1

* Fix LocalLinksManager test URLs

# 32.2.0

* Add LocalLinksManager `local_link` adapter.

# 32.1.0

* Add `publishing_api_has_item_in_sequence` test helper

# 32.0.0

* Allow publishing apps to request a specific version of content.
* Provide a warning message for rummager deprecated stubs
* Modify Rummager test helper to use `rummager` vhost instead of `search`.
  **This is a breaking change**, which means applications currently using the
  helper will need to ensure they are using the `rummager` vhost when creating
  the adapter.

# 31.4.0

* Add `allow_draft` flag that can optionally be set when unpublishing

# 31.3.0

* Add `stub_any_rummager_delete_content` and `assert_rummager_deleted_content`

# 31.2.0

* Add an `area_for_code` method to the MapIt API adapter.

# 31.1.0

* Add a `stub_any_publishing_api_publish` test helper

# 31.0.0

* Remove `format` from expected results in Pact tests.

# 30.9.0

* Add `assert_publishing_api_unpublish` test-helper

# 30.8.0

* Stubs successful and failing attachment uploads to asset manager.

# 30.7.0

* Allow `bulk_publishing` flag for `PublishingApiV2#patch_links`

# 30.6.0

* Use `document_type` & `schema_name` in special routes
* Remove implicit dependency between JsonClient and GdsApi::Base
* Add support for get_expanded_links endpoint

# 30.5.0

* Add `locale` parameter to unpublish endpoint.
* Add publishing-api `stub_publishing_api_unpublish` test helper method.

# 30.4.0

* Add publishing API POST /v2/content/:content_id/unpublish endpoint
  See docs for more info: https://github.com/alphagov/publishing-api/blob/master/doc/api.md#post-v2contentcontent_idunpublish

# 30.3.0

* Add email alert API `GET notifications` and `GET notification` endpoints

# 30.2.1

* Update README and add documentation. See http://www.rubydoc.info/gems/gds-api-adapters/GdsApi/PublishingApiV2 for example.
* Remove content-register

# 30.2.0

* Add `GdsApi::GovukHeaders.clear_headers`

# 30.1.0

* Add stub for `publishing_api_get_content` in `publishing_api_v2` test helper.

# 30.0.1

* Extend publishing API 'stub_publishing_api_publish' test helper to accept a response hash

# 30.0.0

* Change test helper
* Wrap resultant calls to GET /v2/content in meta data

# 29.6.0

* Add `GdsApi::PublishingApiV2#lookup_content_id` and `GdsApi::PublishingApiV2#lookup_content_id`
* Add `publishing_api_has_lookups` test helpers

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
