require "test_helper"
require "gds_api/publishing_api"
require "gds_api/test_helpers/publishing_api"

describe GdsApi::TestHelpers::PublishingApi do
  include GdsApi::TestHelpers::PublishingApi
  let(:publishing_api) { GdsApi::PublishingApi.new(Plek.find("publishing-api")) }

  describe "#stub_publishing_api_has_linked_items" do
    it "stubs the get linked items api call" do
      links = [
        { "content_id" => "id-1", "title" => "title 1", "link_type" => "taxons" },
        { "content_id" => "id-2", "title" => "title 2", "link_type" => "taxons" },
      ]
      stub_publishing_api_has_linked_items(
        links,
        content_id: "content-id",
        link_type: "taxons",
        fields: [:title],
      )

      api_response = publishing_api.get_linked_items(
        "content-id",
        link_type: "taxons",
        fields: [:title],
      )

      assert_equal(
        api_response.to_hash,
        links,
      )
    end
  end

  describe "#stub_publish_api_has_links_for_content_ids" do
    it "stubs the call to get links for content ids" do
      links = {
        "2878337b-bed9-4e7f-85b6-10ed2cbcd504" => {
          "links" => { "taxons" => %w[eb6965c7-3056-45d0-ae50-2f0a5e2e0854] },
        },
        "eec13cea-219d-4896-9c97-60114da23559" => {
          "links" => {},
        },
      }

      stub_publishing_api_has_links_for_content_ids(links)

      assert_equal publishing_api.get_links_for_content_ids(links.keys), links
    end
  end

  describe "#stub_publishing_api_has_lookups" do
    it "stubs the lookup for content items" do
      lookup_hash = { "/foo" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504" }

      stub_publishing_api_has_lookups(lookup_hash)

      assert_equal publishing_api.lookup_content_ids(base_paths: ["/foo"]), lookup_hash
      assert_equal publishing_api.lookup_content_id(base_path: "/foo"), "2878337b-bed9-4e7f-85b6-10ed2cbcd504"
    end
  end

  describe "#stub_publishing_api_has_content" do
    it "stubs the call to get content items" do
      stub_publishing_api_has_content([{ "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504" }])

      response = publishing_api.get_content_items({})["results"]

      assert_equal([{ "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504" }], response)
    end

    it "allows params" do
      stub_publishing_api_has_content(
        [{
          "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504",
        }],
        document_type: "document_collection",
        query: "query",
      )

      response = publishing_api.get_content_items(
        document_type: "document_collection",
        query: "query",
      )["results"]

      assert_equal(
        [{ "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504" }],
        response,
      )
    end

    it "returns paginated results" do
      content_id1 = "2878337b-bed9-4e7f-85b6-10ed2cbcd504"
      content_id2 = "2878337b-bed9-4e7f-85b6-10ed2cbcd505"
      content_id3 = "2878337b-bed9-4e7f-85b6-10ed2cbcd506"

      stub_publishing_api_has_content(
        [
          { "content_id" => content_id1 },
          { "content_id" => content_id2 },
          { "content_id" => content_id3 },
        ],
        page: 1,
        per_page: 2,
      )

      response = publishing_api.get_content_items(page: 1, per_page: 2)
      records = response["results"]

      assert_equal(response["total"], 3)
      assert_equal(response["pages"], 2)
      assert_equal(response["current_page"], 1)

      assert_equal(records.length, 2)
      assert_equal(records.first["content_id"], content_id1)
      assert_equal(records.last["content_id"], content_id2)
    end

    it "returns an empty list of results for out-of-bound queries" do
      content_id1 = "2878337b-bed9-4e7f-85b6-10ed2cbcd504"
      content_id2 = "2878337b-bed9-4e7f-85b6-10ed2cbcd505"

      stub_publishing_api_has_content(
        [
          { "content_id" => content_id1 },
          { "content_id" => content_id2 },
        ],
        page: 10,
        per_page: 2,
      )

      response = publishing_api.get_content_items(page: 10, per_page: 2)
      records = response["results"]

      assert_equal(records, [])
    end
  end

  describe "#stub_publishing_api_has_item" do
    it "stubs the call to get content items" do
      stub_publishing_api_has_item("content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504")
      response = publishing_api.get_content("2878337b-bed9-4e7f-85b6-10ed2cbcd504").parsed_content

      assert_equal({ "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504" }, response)
    end

    it "allows params" do
      stub_publishing_api_has_item(
        "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504",
        "version" => 3,
      )

      response = publishing_api.get_content(
        "2878337b-bed9-4e7f-85b6-10ed2cbcd504",
        "version" => 3,
      ).parsed_content

      assert_equal(
        {
          "content_id" => "2878337b-bed9-4e7f-85b6-10ed2cbcd504",
          "version" => 3,
        },
        response,
      )
    end
  end

  describe "#stub_publishing_api_has_expanded_links" do
    it "stubs the call to get expanded links when content_id is a symbol" do
      payload = {
        content_id: "2e20294a-d694-4083-985e-d8bedefc2354",
        organisations: [
          {
            content_id: %w[a8a09822-1729-48a7-8a68-d08300de9d1e],
          },
        ],
      }

      stub_publishing_api_has_expanded_links(payload)
      response = publishing_api.get_expanded_links("2e20294a-d694-4083-985e-d8bedefc2354")

      assert_equal(
        {
          "content_id" => "2e20294a-d694-4083-985e-d8bedefc2354",
          "organisations" => [
            {
              "content_id" => %w[a8a09822-1729-48a7-8a68-d08300de9d1e],
            },
          ],
        },
        response.to_h,
      )
    end

    it "stubs the call to get expanded links when content_id is a string" do
      payload = {
        "content_id" => "2e20294a-d694-4083-985e-d8bedefc2354",
        organisations: [
          {
            content_id: %w[a8a09822-1729-48a7-8a68-d08300de9d1e],
          },
        ],
      }

      stub_publishing_api_has_expanded_links(payload)
      response = publishing_api.get_expanded_links("2e20294a-d694-4083-985e-d8bedefc2354")

      assert_equal(
        {
          "content_id" => "2e20294a-d694-4083-985e-d8bedefc2354",
          "organisations" => [
            {
              "content_id" => %w[a8a09822-1729-48a7-8a68-d08300de9d1e],
            },
          ],
        },
        response.to_h,
      )
    end

    it "stubs with query parameters" do
      payload = {
        "content_id" => "2e20294a-d694-4083-985e-d8bedefc2354",
        organisations: [
          {
            content_id: %w[a8a09822-1729-48a7-8a68-d08300de9d1e],
          },
        ],
      }

      stub_publishing_api_has_expanded_links(payload, with_drafts: false, generate: true)
      response = publishing_api.get_expanded_links("2e20294a-d694-4083-985e-d8bedefc2354", with_drafts: false, generate: true)

      assert_equal(
        {
          "content_id" => "2e20294a-d694-4083-985e-d8bedefc2354",
          "organisations" => [
            {
              "content_id" => %w[a8a09822-1729-48a7-8a68-d08300de9d1e],
            },
          ],
        },
        response.to_h,
      )
    end
  end

  describe "#stub_publishing_api_patch_links" do
    it "stubs a request to patch links" do
      content_id = SecureRandom.uuid
      body = {
        links: {
          my_linkset: %w[link_1],
        },
        previous_version: 4,
      }

      assert_raises WebMock::NetConnectNotAllowedError do
        publishing_api.patch_links(content_id, body)
      end

      stub_publishing_api_patch_links(content_id, body)
      response = publishing_api.patch_links(content_id, body)
      assert_equal(response.code, 200)
    end
  end

  describe "#stub_publishing_api_patch_links_conflict" do
    it "stubs a request to patch links with a 409 conflict response" do
      content_id = SecureRandom.uuid
      body = {
        links: {
          my_linkset: %w[link_1],
        },
        previous_version: 4,
      }

      stub_publishing_api_patch_links_conflict(content_id, body)

      error = assert_raises GdsApi::HTTPConflict do
        publishing_api.patch_links(content_id, body)
      end

      assert error.message.include?({
        error: {
          code: 409,
          message: "A lock-version conflict occurred. The `previous_version` you've sent (4) is not the same as the current lock version of the edition (5).",
          fields: { previous_version: ["does not match"] },
        },
      }.to_json)
    end
  end

  describe "#stub_any_publishing_api_publish" do
    it "stubs any publish request to the publishing api" do
      stub_any_publishing_api_publish
      publishing_api.publish("some-content-id", "major")
      assert_publishing_api_publish("some-content-id")
    end
  end

  describe "#stub_any_publishing_api_unpublish" do
    it "stubs any unpublish request to the publishing api" do
      stub_any_publishing_api_unpublish
      publishing_api.unpublish("some-content-id", type: :gone)
      assert_publishing_api_unpublish("some-content-id")
    end
  end

  describe "#stub_any_publishing_api_discard_draft" do
    it "stubs any discard draft request to the publishing api" do
      stub_any_publishing_api_discard_draft
      publishing_api.discard_draft("some-content-id")
      assert_publishing_api_discard_draft("some-content-id")
    end
  end

  describe "#stub_publishing_api_get_editions" do
    it "stubs the get editions api call" do
      editions = [
        { "content_id" => "id-1", "title" => "title 1" },
        { "content_id" => "id-2", "title" => "title 2" },
      ]

      stub_publishing_api_get_editions(
        editions,
        fields: %w[title],
      )

      api_response = publishing_api.get_editions(fields: [:title])

      assert_equal(
        api_response["results"],
        [{ "title" => "title 1" }, { "title" => "title 2" }],
      )
    end
  end

  describe "#stub_publishing_api_isnt_available" do
    it "raises a GdsApi::HTTPUnavailable for any request" do
      stub_publishing_api_isnt_available

      assert_raises GdsApi::HTTPUnavailable do
        publishing_api.get_content_items({})
      end
    end
  end

  describe "#stub_any_publishing_api_call" do
    it "returns a 200 response for any request" do
      stub_any_publishing_api_call
      response = publishing_api.get_editions
      assert_equal(response.code, 200)
    end
  end

  describe "#stub_any_publishing_api_call_to_return_not_found" do
    it "returns a GdsApi::HTTPNotFound for any request" do
      stub_any_publishing_api_call_to_return_not_found
      assert_raises GdsApi::HTTPNotFound do
        publishing_api.get_editions
      end
    end
  end

  describe "#stub_publishing_api_put_intent" do
    it "stubs the put intent endpoint" do
      params = { publishing_app: "publisher",
                 rendering_app: "frontend",
                 publish_time: "2019-11-11t17:56:17+00:00" }
      stub_publishing_api_put_intent("/foo", params)
      api_response = publishing_api.put_intent("/foo", params)
      assert_equal(api_response.code, 200)

      assert_equal(
        {
          "publishing_app" => "publisher",
          "rendering_app" => "frontend",
          "publish_time" => "2019-11-11t17:56:17+00:00",
        },
        api_response.to_h,
      )
    end

    it "accepts parameters as a string" do
      stub_publishing_api_put_intent("/foo", '"string"')
      api_response = publishing_api.put_intent("/foo", "string")
      assert_equal('"string"', api_response.raw_response_body)
    end
  end

  describe "#stub_publishing_api_unreserve_path" do
    it "stubs the unreserve path API call" do
      stub_publishing_api_unreserve_path("/foo", "myapp")
      api_response = publishing_api.unreserve_path("/foo", "myapp")
      assert_equal(api_response.code, 200)
    end

    it "stubs for any app if not specified" do
      stub_publishing_api_unreserve_path("/foo")
      api_response = publishing_api.unreserve_path("/foo", "myapp")
      assert_equal(api_response.code, 200)
    end
  end

  describe "#stub_publishing_api_unreserve_path_not_found" do
    it "stubs the unreserve path API call" do
      stub_publishing_api_unreserve_path_not_found("/foo", "myapp")

      assert_raises GdsApi::HTTPNotFound do
        publishing_api.unreserve_path("/foo", "myapp")
      end
    end

    it "stubs for any app if not specified" do
      stub_publishing_api_unreserve_path_not_found("/foo")

      assert_raises GdsApi::HTTPNotFound do
        publishing_api.unreserve_path("/foo", "myapp")
      end
    end
  end

  describe "#stub_publishing_api_unreserve_path_invalid" do
    it "stubs the unreserve path API call" do
      stub_publishing_api_unreserve_path_invalid("/foo", "myapp")

      assert_raises GdsApi::HTTPUnprocessableEntity do
        publishing_api.unreserve_path("/foo", "myapp")
      end
    end

    it "stubs for any app if not specified" do
      stub_publishing_api_unreserve_path_invalid("/foo")

      assert_raises GdsApi::HTTPUnprocessableEntity do
        publishing_api.unreserve_path("/foo", "myapp")
      end
    end
  end

  describe "#stub_any_publishing_api_unreserve_path" do
    it "stubs a request to unreserve a path" do
      stub_any_publishing_api_unreserve_path

      api_response = publishing_api.unreserve_path("/foo", "myapp")
      assert_equal(api_response.code, 200)
    end
  end

  describe "#stub_any_publishing_api_path_reservation" do
    it "stubs a request to reserve a path" do
      stub_any_publishing_api_path_reservation

      api_response = publishing_api.put_path("/foo", {})
      assert_equal(api_response.code, 200)
    end

    it "returns the payload with the base_path merged in" do
      stub_any_publishing_api_path_reservation

      api_response = publishing_api.put_path("/foo", publishing_app: "foo-publisher")
      assert_equal(
        {
          "publishing_app" => "foo-publisher",
          "base_path" => "/foo",
        },
        api_response.to_h,
      )
    end
  end

  describe "#stub_publishing_api_has_path_reservation_for" do
    it "returns successfully for a request for the path and publishing app" do
      stub_publishing_api_has_path_reservation_for("/foo", "foo-publisher")

      api_response = publishing_api.put_path("/foo", publishing_app: "foo-publisher")
      assert_equal(api_response.code, 200)
      assert_equal(
        {
          "publishing_app" => "foo-publisher",
          "base_path" => "/foo",
        },
        api_response.to_h,
      )
    end

    it "returns an error response for a request for the path and a different publishing app" do
      stub_publishing_api_has_path_reservation_for("/foo", "foo-publisher")

      error = assert_raises GdsApi::HTTPUnprocessableEntity do
        publishing_api.put_path("/foo", publishing_app: "bar-publisher")
      end

      assert error.message.include?({
        error: {
          code: 422,
          message: "Base path /foo is already reserved by foo-publisher",
          fields: { base_path: ["/foo is already reserved by foo-publisher"] },
        },
      }.to_json)
    end
  end

  describe "#stub_publishing_api_returns_path_reservation_validation_error_for" do
    it "returns a validation error for a particular path" do
      stub_publishing_api_returns_path_reservation_validation_error_for("/foo")

      error = assert_raises GdsApi::HTTPUnprocessableEntity do
        publishing_api.put_path("/foo", {})
      end

      assert error.message.include?({
        error: {
          code: 422,
          message: "Base path Computer says no",
          fields: { base_path: ["Computer says no"] },
        },
      }.to_json)
    end

    it "can accept user provided errors" do
      stub_publishing_api_returns_path_reservation_validation_error_for(
        "/foo",
        field: ["error 1", "error 2"],
      )

      error = assert_raises GdsApi::HTTPUnprocessableEntity do
        publishing_api.put_path("/foo", {})
      end

      assert error.message.include?({
        error: {
          code: 422,
          message: "Field error 1",
          fields: { field: ["error 1", "error 2"] },
        },
      }.to_json)
    end
  end

  describe "#stub_publishing_api_has_schemas" do
    it "returns the given schemas" do
      schemas = {
        "email_address" => {
          "type": "email_address",
          "required": %w[email],
          "properties": {
            "email": { "type" => "string" },
          },
        },
        "tax_bracket" => {
          "type": "tax_bracket",
          "required": %w[code],
          "properties": {
            "code": { "type" => "string" },
          },
        },
      }

      stub_publishing_api_has_schemas(
        schemas,
      )

      api_response = publishing_api.get_schemas

      assert_equal(
        schemas.to_json,
        api_response.to_json,
      )
    end
  end

  describe "#stub_publishing_api_has_schemas_for_schema_name" do
    it "returns the given schema" do
      schema_name = "email_address"

      schema = {
        "email_address" => {
          "type": "email_address",
          "required": %w[email],
          "properties": {
            "email": { "type" => "string" },
          },
        },
      }

      stub_publishing_api_has_schemas_for_schema_name(
        schema_name,
        schema,
      )

      api_response = publishing_api.get_schema(schema_name)

      assert_equal(
        schema.to_json,
        api_response.to_json,
      )
    end
  end

  describe "#stub_publishing_api_schema_name_path_to_return_not_found" do
    it "returns a GdsApi::HTTPNotFound for a call to get a schema by name" do
      schema_name = "missing_schema"

      stub_publishing_api_schema_name_path_to_return_not_found(schema_name)

      assert_raises GdsApi::HTTPNotFound do
        publishing_api.get_schema(schema_name)
      end
    end
  end

  describe "#stub_publishing_api_graphql_query" do
    it "returns the given response" do
      query = "some query"

      stubbed_response = {
        data: {
          edition: {
            title: "some title",
          },
        },
      }

      stub_publishing_api_graphql_query(
        query,
        stubbed_response,
      )

      api_response = publishing_api.graphql_query(query)

      assert_equal(
        stubbed_response.to_json,
        api_response.raw_response_body,
      )
    end
  end

  describe "#stub_publishing_api_graphql_content_item" do
    it "returns the given response" do
      query = "some query"

      stubbed_response = {
        data: {
          edition: {
            title: "some title",
          },
        },
      }

      expected_response = {
        title: "some title",
      }

      stub_publishing_api_graphql_content_item(
        query,
        stubbed_response,
      )

      api_response = publishing_api.graphql_content_item(query)

      assert_equal(
        expected_response.to_json,
        api_response.raw_response_body,
      )
    end

    it "returns the error data when the edition has been unpublished" do
      query = "some query"

      stubbed_response = {
        data: {
          edition: nil,
        },
        errors: [
          {
            message: "Edition has been unpublished",
            extensions: {
              "document_type": "gone",
              "schema_name": "gone",
            },
          },
        ],
      }

      expected_response = {
        "document_type": "gone",
        "schema_name": "gone",
      }

      stub_publishing_api_graphql_content_item(
        query,
        stubbed_response,
      )

      api_response = publishing_api.graphql_content_item(query)

      assert_equal(
        expected_response.to_json,
        api_response.raw_response_body,
      )
    end
  end

  describe "#request_json_matching predicate" do
    describe "nested required attribute" do
      let(:matcher) { request_json_matching("a" => { "b" => 1 }) }

      it "matches a body with exact same nested hash strucure" do
        assert matcher.call(stub("request", body: '{"a": {"b": 1}}'))
      end

      it "matches a body with exact same nested hash strucure and an extra attribute at the top level" do
        assert matcher.call(stub("request", body: '{"a": {"b": 1}, "c": 3}'))
      end

      it "does not match a body where the inner hash has the required attribute and an extra one" do
        refute matcher.call(stub("request", body: '{"a": {"b": 1, "c": 2}}'))
      end

      it "does not match a body where the inner hash has the required attribute with the wrong value" do
        refute matcher.call(stub("request", body: '{"a": {"b": 0}}'))
      end

      it "does not match a body where the inner hash lacks the required attribute" do
        refute matcher.call(stub("request", body: '{"a": {"c": 1}}'))
      end
    end

    describe "hash to match uses symbol keys" do
      let(:matcher) { request_json_matching(a: 1) }

      it "matches a json body" do
        assert matcher.call(stub("request", body: '{"a": 1}'))
      end
    end
  end

  describe "#request_json_including predicate" do
    describe "no required attributes" do
      let(:matcher) { request_json_including({}) }

      it "matches an empty body" do
        assert matcher.call(stub("request", body: "{}"))
      end

      it "matches a body with some attributes" do
        assert matcher.call(stub("request", body: '{"a": 1}'))
      end
    end

    describe "one required attribute" do
      let(:matcher) { request_json_including("a" => 1) }

      it "does not match an empty body" do
        refute matcher.call(stub("request", body: "{}"))
      end

      it "does not match a body with the required attribute if the value is different" do
        refute matcher.call(stub("request", body: '{"a": 2}'))
      end

      it "matches a body with the required attribute and value" do
        assert matcher.call(stub("request", body: '{"a": 1}'))
      end

      it "matches a body with the required attribute and value and extra attributes" do
        assert matcher.call(stub("request", body: '{"a": 1, "b": 2}'))
      end
    end

    describe "nested required attribute" do
      let(:matcher) { request_json_including("a" => { "b" => 1 }) }

      it "matches a body with exact same nested hash strucure" do
        assert matcher.call(stub("request", body: '{"a": {"b": 1}}'))
      end

      it "matches a body where the inner hash has the required attribute and an extra one" do
        assert matcher.call(stub("request", body: '{"a": {"b": 1, "c": 2}}'))
      end

      it "does not match a body where the inner hash has the required attribute with the wrong value" do
        refute matcher.call(stub("request", body: '{"a": {"b": 0}}'))
      end

      it "does not match a body where the inner hash lacks the required attribute" do
        refute matcher.call(stub("request", body: '{"a": {"c": 1}}'))
      end
    end

    describe "hash to match uses symbol keys" do
      let(:matcher) { request_json_including(a: { b: 1 }) }

      it "matches a json body" do
        assert matcher.call(stub("request", body: '{"a": {"b": 1}}'))
      end
    end

    describe "nested arrays" do
      let(:matcher) { request_json_including("a" => [1]) }

      it "matches a body with exact same inner array" do
        assert matcher.call(stub("request", body: '{"a": [1]}'))
      end

      it "does not match a body with an array with extra elements" do
        refute matcher.call(stub("request", body: '{"a": [1, 2]}'))
      end
    end

    describe "hashes in nested arrays" do
      let(:matcher) { request_json_including("a" => [{ "b" => 1 }, 2]) }

      it "matches a body with exact same inner array" do
        assert matcher.call(stub("request", body: '{"a": [{"b": 1}, 2]}'))
      end

      it "matches a body with an inner hash with extra elements" do
        assert matcher.call(stub("request", body: '{"a": [{"b": 1, "c": 3}, 2]}'))
      end
    end
  end
end
