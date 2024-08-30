# GDS API Adapters

A set of API adapters to work with the GDS APIs.

Example usage:

```ruby
GdsApi.publishing_api.get_content("f3bbdec2-0e62-4520-a7fd-6ffd5d36e03a")
```

Example adapters for frequently used applications:

- [Publishing API](lib/gds_api/publishing_api.rb) ([docs](http://www.rubydoc.info/gems/gds-api-adapters/GdsApi/PublishingApi), [test helper code](https://github.com/alphagov/gds-api-adapters/blob/master/lib/gds_api/test_helpers/publishing_api.rb), [test helper docs](http://www.rubydoc.info/gems/gds-api-adapters/GdsApi/TestHelpers/PublishingApi))
- [Content Store](lib/gds_api/content_store.rb) ([docs](http://www.rubydoc.info/gems/gds-api-adapters/GdsApi/ContentStore), [test helper code](https://github.com/alphagov/gds-api-adapters/blob/master/lib/gds_api/test_helpers/content_store.rb), [test helper docs](http://www.rubydoc.info/gems/gds-api-adapters/GdsApi/TestHelpers/ContentStore))
- [Search API](lib/gds_api/search.rb) ([docs](http://www.rubydoc.info/gems/gds-api-adapters/GdsApi/Search), [test helper code](https://github.com/alphagov/gds-api-adapters/blob/master/lib/gds_api/test_helpers/search.rb), [test helper docs](http://www.rubydoc.info/gems/gds-api-adapters/GdsApi/TestHelpers/Search))

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
`GdsApi::TimedOutException` will be raised. You can override this by doing:
that uses the adapter with:

```ruby
adapter = GdsApi.publishing_api(timeout: <number_of_seconds>)
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

## Test Helpers

There are also test helpers for stubbing various requests in other apps.

See [all the test helpers in lib/gds_api/test_helpers](/lib/gds_api/test_helpers).


## Pact Verification During CI

During the CI test suite, Jenkins downloads and runs the pact:verify tasks for
each provider app. It's run directly on the Jenkins machine rather than in
docker containers for each app. For this reason the email-alert-api app
requires a specific setup on the CI machine - on db creation it copies the
database from the template1 db (this is the usual PG behaviour, but for some
reason rails needs to be told to do this explicitly). This template1 db has
to have the uuid-ossp extension installed by superuser, because the jenkins
user that CI runs under cannot create this extension. If this test stops
working with errors like:

```
Caused by:
PG::InsufficientPrivilege: ERROR:  permission denied to create extension "uuid-ossp"
HINT:  Must be superuser to create this extension.
```

...the template may have been deleted or changed. Log in to the relevant CI
agent and run:

`> sudo -u postgres psql -d template1`

Then at the PSQL command line:

`template1=# CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`

## Releasing

1. Read the CHANGELOG.md and decide on the new semantic version number
1. Create a release branch, eg. `release-96.0.3`
1. Update the CHANGELOG.md
    - Declare a new version number
    - Move all unreleased changes beneath it
1. Update `lib/gds_api/version.rb` to match, eg

    ```ruby
      module GdsApi
        VERSION = "96.0.3".freeze
      end
    ```

1. Copy the lines from the CHANGELOG.md into the git commit
1. Propose and merge the pull request into `main`

Nb:

- You do not need to set any git tags
- After merging, CI will release the new version of the gem and Dependabot will
  propose the new version of the gem to help distribute the changes to consumers

## Licence

Released under the MIT Licence, a copy of which can be found in the file
`LICENCE`.
