A set of API adapters to work with the GDS APIs, extracted from the frontend app.

Example usage:

    publisher_api = GdsApi::Publisher.new("environment")
    ostruct_publication = publisher.publication_for_slug('my-published-item')

    panopticon_api = GdsApi::Panopticon.new("environment")
    ostruct_metadata = panopticon_api.artefact_for_slug('my-published-item')

Very much still a work in progress.

## Test Helpers

There's also a test helper for stubbing panopticon requests in other apps. Example usage:

In test_helper.rb:

    require 'gds_api/test_helpers/panopticon'
    
    class ActiveSupport::TestCase
      include GdsApi::TestHelpers::Panopticon
    end

In the test:
  
    panopticon_has_metadata('id' => 12345, 'need_id' => need.id, 'slug' => 'my_slug')
  