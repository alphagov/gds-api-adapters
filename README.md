A set of API adapters to work with the GDS APIs, extracted from the frontend
app.

Example usage:

    publisher_api = GdsApi::Publisher.new("environment")
    ostruct_publication = publisher.publication_for_slug('my-published-item')

    panopticon_api = GdsApi::Panopticon.new("environment")
    ostruct_metadata = panopticon_api.artefact_for_slug('my-published-item')

Very much still a work in progress.

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

    GdsApi::Base.logger = Logger.new("/path/to/file.log")

## Test Helpers

There are also test helpers for stubbing various requests in other apps.
Example usage of the panopticon helper:

In test_helper.rb:

    require 'gds_api/test_helpers/panopticon'

    class ActiveSupport::TestCase
      include GdsApi::TestHelpers::Panopticon
    end

In the test:

    panopticon_has_metadata('id' => 12345, 'need_id' => need.id,
      'slug' => 'my_slug')

This presumes you have webmock installed and enabled.

## To Do

* Make timeout handling work
