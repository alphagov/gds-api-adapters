require 'test_helper'
require 'gds_api/publishing_api_v2'
require 'gds_api/test_helpers/publishing_api_v2'

describe GdsApi::TestHelpers::PublishingApiV2 do
  include GdsApi::TestHelpers::PublishingApiV2
  let(:publishing_api) { GdsApi::PublishingApiV2.new(Plek.current.find("publishing-api")) }

  describe '#publishing_api_has_linked_items' do
    it "stubs the get linked items api call" do
      links = [
        { 'content_id' => 'id-1', 'title' => 'title 1', 'link_type' => 'taxons' },
        { 'content_id' => 'id-2', 'title' => 'title 2', 'link_type' => 'taxons' },
      ]
      publishing_api_has_linked_items(
        links,
        content_id: 'content-id',
        link_type: 'taxons',
        fields: [:title]
      )

      api_response = publishing_api.get_linked_items(
        'content-id',
        link_type: 'taxons',
        fields: [:title]
      )

      assert_equal(
        api_response.to_hash,
        links
      )
    end
  end

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
      publishing_api_has_content([{ "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504" }])

      response = publishing_api.get_content_items({})['results']

      assert_equal([{ "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504" }], response)
    end

    it 'allows params' do
      publishing_api_has_content(
        [{
          "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504"
        }],
        document_type: 'document_collection',
        query: 'query',
      )

      response = publishing_api.get_content_items(
        document_type: 'document_collection',
        query: 'query'
      )['results']

      assert_equal(
        [{ "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504" }],
        response
      )
    end

    it 'returns paginated results' do
      content_id_1 = "2878337b-bed9-4e7f-85b6-10ed2cbcd504"
      content_id_2 = "2878337b-bed9-4e7f-85b6-10ed2cbcd505"
      content_id_3 = "2878337b-bed9-4e7f-85b6-10ed2cbcd506"

      publishing_api_has_content(
        [
          { "content_id" => content_id_1 },
          { "content_id" => content_id_2 },
          { "content_id" => content_id_3 },
        ],
                  page: 1,
          per_page: 2
      )

      response = publishing_api.get_content_items(page: 1, per_page: 2)
      records = response['results']

      assert_equal(response['total'], 3)
      assert_equal(response['pages'], 2)
      assert_equal(response['current_page'], 1)

      assert_equal(records.length, 2)
      assert_equal(records.first['content_id'], content_id_1)
      assert_equal(records.last['content_id'], content_id_2)
    end

    it 'returns an empty list of results for out-of-bound queries' do
      content_id_1 = "2878337b-bed9-4e7f-85b6-10ed2cbcd504"
      content_id_2 = "2878337b-bed9-4e7f-85b6-10ed2cbcd505"

      publishing_api_has_content(
        [
          { "content_id" => content_id_1 },
          { "content_id" => content_id_2 },
        ],
                  page: 10,
          per_page: 2
      )

      response = publishing_api.get_content_items(page: 10, per_page: 2)
      records = response['results']

      assert_equal(records, [])
    end
  end

  describe "#publishing_api_has_item" do
    it "stubs the call to get content items" do
      publishing_api_has_item("content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504")
      response = publishing_api.get_content("2878337b-bed9-4e7f-85b6-10ed2cbcd504").parsed_content

      assert_equal({ "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504" }, response)
    end

    it 'allows params' do
      publishing_api_has_item(
        "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504",
        "version" => 3,
      )

      response = publishing_api.get_content(
        "2878337b-bed9-4e7f-85b6-10ed2cbcd504",
        "version" => 3,
      ).parsed_content

      assert_equal({
          "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504",
          "version" => 3
        },
        response
      )
    end
  end

  describe "#publishing_api_has_expanded_links" do
    it "stubs the call to get expanded links when content_id is a symbol" do
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

    it "stubs the call to get expanded links when content_id is a string" do
      payload = {
        "content_id" => "2e20294a-d694-4083-985e-d8bedefc2354",
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

    it "stubs with query parameters" do
      payload = {
        "content_id" => "2e20294a-d694-4083-985e-d8bedefc2354",
        organisations: [
          {
            content_id: ["a8a09822-1729-48a7-8a68-d08300de9d1e"]
          }
        ]
      }

      publishing_api_has_expanded_links(payload, with_drafts: false)
      response = publishing_api.get_expanded_links("2e20294a-d694-4083-985e-d8bedefc2354", with_drafts: false)

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

  describe "stub_any_publishing_api_publish" do
    it "stubs any publish request to the publishing api" do
      stub_any_publishing_api_publish
      publishing_api.publish("some-content-id", "major")
      assert_publishing_api_publish("some-content-id")
    end
  end

  describe "stub_any_publishing_api_unpublish" do
    it "stubs any unpublish request to the publishing api" do
      stub_any_publishing_api_unpublish
      publishing_api.unpublish("some-content-id", type: :gone)
      assert_publishing_api_unpublish("some-content-id")
    end
  end

  describe "stub_any_publishing_api_discard_draft" do
    it "stubs any discard draft request to the publishing api" do
      stub_any_publishing_api_discard_draft
      publishing_api.discard_draft("some-content-id")
      assert_publishing_api_discard_draft("some-content-id")
    end
  end
end
