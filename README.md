# GDS API Adapters

A set of API adapters to work with the GDS APIs.

Example usage:

```ruby
require 'gds_api/rummager'
rummager = GdsApi::Rummager.new(Plek.new.find('rummager'))
results = rummager.search(q: "taxes")
```

Example adapters for frequently used applications:

- [Publishing API](lib/gds_api/publishing_api_v2.rb) ([docs](http://www.rubydoc.info/gems/gds-api-adapters/GdsApi/PublishingApiV2), [test helper code](https://github.com/alphagov/gds-api-adapters/blob/master/lib/gds_api/test_helpers/publishing_api_v2.rb), [test helper docs](http://www.rubydoc.info/gems/gds-api-adapters/GdsApi/TestHelpers/PublishingApiV2))
- [Content Store](lib/gds_api/content_store.rb) ([docs](http://www.rubydoc.info/gems/gds-api-adapters/GdsApi/ContentStore), [test helper code](https://github.com/alphagov/gds-api-adapters/blob/master/lib/gds_api/test_helpers/content_store.rb), [test helper docs](http://www.rubydoc.info/gems/gds-api-adapters/GdsApi/TestHelpers/ContentStore))
- [Rummager](lib/gds_api/rummager.rb) ([docs](http://www.rubydoc.info/gems/gds-api-adapters/GdsApi/Rummager), [test helper code](https://github.com/alphagov/gds-api-adapters/blob/master/lib/gds_api/test_helpers/rummager.rb), [test helper docs](http://www.rubydoc.info/gems/gds-api-adapters/GdsApi/TestHelpers/Rummager))

## Configuration

We're currently deprecating some behaviour of this gem. You can opt-in to the
new behaviour now by adding configuration like this:

```ruby
# config/initializers/gds_api_adapters.rb
GdsApi.configure do |config|
  # Never return nil when a server responds with 404 or 410.
  config.always_raise_for_not_found = true

  # Return a hash, not an OpenStruct from a request.
  config.hash_response_for_requests = true
end
```

## Logging

Each HTTP request can be logged as JSON. Example:

    {
      "request_uri":"http://contactotron.platform/contacts/1",
      "start_time":1324035128.9056342,
      "status":"success",
      "end_time":1324035129.2017104
    }


By default we log to a NullLogger since we don't want to pollute your test
results or logs. To log output you'll want to set `GdsApi::Base.logger` to
something that actually logs:

```ruby
GdsApi::Base.logger = Logger.new("/path/to/file.log")
```

## Setting the timeout

By default the JsonClient timeout is set to 4 seconds. If this is exceeded a
`GdsApi::TimedOutException` will be raised. Individual clients may decide to
override this timeout. Alternatively, you can override this in the application
that uses the adapter with:

```ruby
Services.publishing_api.client.options[:timeout] = number_of_seconds
```

In most cases, there is an upper-limit of 30 seconds imposed by the app server
or Nginx. If your requests are taking this long, you should probably be looking
into other options to lower the response time.

## Middleware for request tracing

We set a unique header at the cache level called `Govuk-Request-Id`, and also
set a header called `Govuk-Original-Url` to identify the original URL
requested.  If apps make API requests in order to serve a user's request, they
should pass on these headers, so that requests can be traced across the entire
GOV.UK stack.

The `GdsApi::GovukHeaderSniffer` middleware takes care of this. This gem
contains a railtie that configures this middleware for Rails apps without extra
effort.  Other Rack-based apps should opt-in by adding these lines to your
`config.ru`:

    use GdsApi::GovukHeaderSniffer, 'HTTP_GOVUK_REQUEST_ID'
    use GdsApi::GovukHeaderSniffer, 'HTTP_GOVUK_ORIGINAL_URL'

## Middleware for identifying authenticated users

Applications can make use of user-based identification for additional
authorisation when making API requests. Any application that is using gds-sso
for authentication can set an additional header called
'X-Govuk-Authenticated-User' to identify the currently authenticated user ID.
This will automatically be picked up by the `GdsApi::GovukHeaderSniffer`
middleware in Rails applications and sent with API requests so that the
downstream service can optionally use the identifier to perform authorisation
on the request. This will be used by content-store as a mechanism to only
return access-limited content to authenticated and authorised users.

## App-level Authentication

The API Adapters currently support either HTTP Basic or OAuth2 (bearer token)
authentication. This allows an application to identify itself to another where
required. This is currently used by the `GdsApi::Panopticon::Registerer`
adapter, which  expects a constant called `PANOPTICON_API_CREDENTIALS` to be
defined that identifies the calling application to Panopticon:

    PANOPTICON_API_CREDENTIALS = { bearer_token: 'MY_BEARER_TOKEN' }

## Test Helpers

There are also test helpers for stubbing various requests in other apps.
Example usage of the panopticon helper:

In `test_helper.rb`:

    require 'gds_api/test_helpers/panopticon'

    class ActiveSupport::TestCase
      include GdsApi::TestHelpers::Panopticon
    end

In the test:

    panopticon_has_metadata('id' => 12345, 'need_ids' => [need.id],
      'slug' => 'my_slug')

### Dependencies

Some of the helpers come with additional dependencies that you'll need to
have installed and configured in your consuming app/lib.

At time of writing, these are:

* [WebMock](https://github.com/bblimke/webmock)

### Documentation

See [RubyDoc](http://www.rubydoc.info/gems/gds-api-adapters) for some limited documentation.

To run a Yard server locally to preview documentation, run:

    $ bundle exec yard server --reload

### Contribution

See [CONTRIBUTNG.md](CONTRIBUTNG.md).

## Licence

Released under the MIT Licence, a copy of which can be found in the file
`LICENCE`.
