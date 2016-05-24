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

  describe "#publishing_api_has_content" do
    it "stubs the call to get content items" do
      publishing_api_has_content([{"content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504"}])

      response = publishing_api.get_content_items({})['results']

      assert_equal([{ "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504" }], response)
    end
  end

  describe "#publishing_api_has_expanded_links" do
    it "stubs the call to get expanded links" do
      payload = {
        content_id: "2e20294a-d694-4083-985e-d8bedefc2354",
        organisations: [
          {
            content_id: ["a8a09822-1729-48a7-8a68-d08300de9d1e"]
          }
        ]
      }

      publishing_api_has_expanded_links(payload)
      response = publishing_api.get_expanded_links("2e20294a-d694-4083-985e-d8bedefc2354")

      assert_equal({
        "content_id" => "2e20294a-d694-4083-985e-d8bedefc2354",
        "organisations" => [
          {
            "content_id" => ["a8a09822-1729-48a7-8a68-d08300de9d1e"]
          }
        ]
      }, response.to_h)
    end
  end

  describe "#publishing_api_has_grouped_content_and_links" do
    it "stubs the call to get grouped_content_and links" do
      content_id = "2e20294a-d694-4083-985e-d8bedefc2354"
      payload = [
        {
          "content_id" => content_id,
          "content_items" => [{
            "base_path" => "/foo",
            "publishing_app" => "whitehall",
            "format" => "guide",
            "user_facing_version" => "1",
            "state" => "published"
          }],
          "links" => {
            "organisations" => ["a8a09822-1729-48a7-8a68-d08300de9d1e"]
          }
        }
      ]

      publishing_api_has_grouped_content_and_links(payload)
      response = publishing_api.get_grouped_content_and_links

      assert_equal(response["results"], payload)
      assert_equal(response["last_seen_content_id"], content_id)
    end
  end
end
