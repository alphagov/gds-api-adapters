require 'test_helper'
require 'gds_api/publishing_api_v2'
require 'gds_api/test_helpers/publishing_api_v2'

describe GdsApi::TestHelpers::PublishingApiV2 do
  include GdsApi::TestHelpers::PublishingApiV2
  let(:publishing_api) { GdsApi::PublishingApiV2.new(Plek.current.find("publishing-api")) }

  describe "#publishing_api_has_lookups" do
    it "stubs the lookup for content items" do
      lookup_hash = { "/foo" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504" }

      publishing_api_has_lookups(lookup_hash)

      assert_equal publishing_api.lookup_content_ids(base_paths: ["/foo"]), lookup_hash
      assert_equal publishing_api.lookup_content_id(base_path: "/foo"), "2878337b-bed9-4e7f-85b6-10ed2cbcd504"
    end
  end
end
