require "test_helper"
require "gds_api/publishing_api"

describe GdsApi::PublishingApi do
  include PactTest

  let(:bearer_token) { "example-bearer-token" }
  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host, bearer_token: bearer_token) }
  let(:content_id) { "bed722e6-db68-43e5-9079-063f623335a7" }

  describe "#put_content" do
    it "responds with 200 OK if the entry is valid" do
      content_item = content_item_for_content_id(content_id)

      publishing_api
        .given("no content exists")
        .upon_receiving("a request to create a content item without links")
        .with(
          method: :put,
          path: "/v2/content/#{content_id}",
          body: content_item,
          headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 200,
        )

      api_client.put_content(content_id, content_item)
    end

    it "responds with 422 Unprocessable Entity if the path is reserved by a different app" do
      content_item = content_item_for_content_id(content_id, "base_path" => "/test-item", "publishing_app" => "whitehall")

      publishing_api
        .given("/test-item has been reserved by the Publisher application")
        .upon_receiving("a request from the Whitehall application to create a content item at /test-item")
        .with(
          method: :put,
          path: "/v2/content/#{content_id}",
          body: content_item,
          headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 422,
          body: {
            "error" => {
              "code" => 422,
              "message" => Pact.term(generate: "Conflict", matcher: /\S+/),
              "fields" => {
                "base_path" => Pact.each_like("is already in use by the 'publisher' app", min: 1),
              },
            },
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      assert_raises(GdsApi::HTTPUnprocessableEntity) do
        api_client.put_content(content_id, content_item)
      end
    end

    it "responds with 422 Unprocessable Entity when given an invalid item" do
      content_item = content_item_for_content_id(content_id, "base_path" => "not a url path")

      publishing_api
        .given("no content exists")
        .upon_receiving("a request to create an invalid content-item")
        .with(
          method: :put,
          path: "/v2/content/#{content_id}",
          body: content_item,
          headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 422,
          body: [
            {
              schema: Pact.like({}),
              fragment: "#/base_path",
              message: Pact.like("The property '#/base_path' value \"not a url path\" did not match the regex '^/(([a-zA-Z0-9._~!$&'()*+,;=:@-]|%[0-9a-fA-F]{2})+(/([a-zA-Z0-9._~!$&'()*+,;=:@-]|%[0-9a-fA-F]{2})*)*)?$' in schema 729a13d6-8ddb-5ba8-b116-3b7604dc3d3d#"),
              failed_attribute: "Pattern",
            },
          ],
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      assert_raises(GdsApi::HTTPUnprocessableEntity) do
        api_client.put_content(content_id, content_item)
      end
    end

    describe "optimistic locking" do
      it "responds with 200 OK if the content item has not changed since it was requested" do
        content_item = content_item_for_content_id(
          content_id,
          "document_type" => "manual",
          "schema_name" => "manual",
          "locale" => "en",
          "details" => { "body" => [] },
          "previous_version" => "3",
        )

        publishing_api
          .given("the content item #{content_id} is at version 3")
          .upon_receiving("a request to update the content item at version 3")
          .with(
            method: :put,
            path: "/v2/content/#{content_id}",
            body: content_item,
            headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 200,
          )

        api_client.put_content(content_id, content_item)
      end

      it "responds with 409 Conflict if the content item has changed in the meantime" do
        content_item = content_item_for_content_id(
          content_id,
          "document_type" => "manual",
          "schema_name" => "manual",
          "locale" => "en",
          "details" => { "body" => [] },
          "previous_version" => "2",
        )

        publishing_api
          .given("the content item #{content_id} is at version 3")
          .upon_receiving("a request to update the content item at version 2")
          .with(
            method: :put,
            path: "/v2/content/#{content_id}",
            body: content_item,
            headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 409,
            body: {
              "error" => {
                "code" => 409,
                "message" => Pact.term(generate: "Conflict", matcher: /\S+/),
                "fields" => {
                  "previous_version" => Pact.each_like("does not match", min: 1),
                },
              },
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

        assert_raises(GdsApi::HTTPConflict) do
          api_client.put_content(content_id, content_item)
        end
      end
    end
  end

  describe "#get_content" do
    it "responds with 200 and the content item when the content item exists" do
      publishing_api
        .given("a content item exists with content_id: #{content_id}")
        .upon_receiving("a request to return the content item")
        .with(
          method: :get,
          path: "/v2/content/#{content_id}",
          headers: GdsApi::JsonClient.default_request_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 200,
          body: {
            "content_id" => content_id,
            "document_type" => Pact.like("special_route"),
            "schema_name" => Pact.like("special_route"),
            "publishing_app" => Pact.like("publisher"),
            "rendering_app" => Pact.like("frontend"),
            "locale" => Pact.like("en"),
            "routes" => Pact.like([{}]),
            "public_updated_at" => Pact.like("2015-07-30T13:58:11.000Z"),
            "details" => Pact.like({}),
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.get_content(content_id)
    end

    it "responds with 200 and the content item when a content item exists in multiple locales" do
      publishing_api
        .given("a content item exists in multiple locales with content_id: #{content_id}")
        .upon_receiving("a request to return the content item")
        .with(
          method: :get,
          path: "/v2/content/#{content_id}",
          query: "locale=fr",
          headers: GdsApi::JsonClient.default_request_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 200,
          body: {
            "content_id" => content_id,
            "document_type" => Pact.like("special_route"),
            "schema_name" => Pact.like("special_route"),
            "publishing_app" => Pact.like("publisher"),
            "rendering_app" => Pact.like("frontend"),
            "locale" => "fr",
            "routes" => Pact.like([{}]),
            "public_updated_at" => Pact.like("2015-07-30T13:58:11.000Z"),
            "details" => Pact.like({}),
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.get_content(content_id, locale: "fr")
    end

    it "responds with 200 and the superseded content item when requesting the superseded version, when a content item exists in with a superseded version" do
      publishing_api
        .given("a content item exists in with a superseded version with content_id: #{content_id}")
        .upon_receiving("a request to return the superseded content item")
        .with(
          method: :get,
          path: "/v2/content/#{content_id}",
          query: "version=1",
          headers: GdsApi::JsonClient.default_request_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 200,
          body: {
            "content_id" => content_id,
            "document_type" => Pact.like("special_route"),
            "schema_name" => Pact.like("special_route"),
            "publishing_app" => Pact.like("publisher"),
            "rendering_app" => Pact.like("frontend"),
            "locale" => Pact.like("en"),
            "routes" => Pact.like([{}]),
            "public_updated_at" => Pact.like("2015-07-30T13:58:11.000Z"),
            "details" => Pact.like({}),
            "publication_state" => "superseded",
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.get_content(content_id, version: 1)
    end

    it "responds with 200 and the draft content item containing a warning, when a content item cannot be published because of a path conflict" do
      publishing_api
        .given("a draft content item exists with content_id #{content_id} with a blocking live item at the same path")
        .upon_receiving("a request to return the draft content item")
        .with(
          method: :get,
          path: "/v2/content/#{content_id}",
          headers: GdsApi::JsonClient.default_request_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 200,
          body: {
            "warnings" => Pact.like("content_item_blocking_publish" => "message"),
            "content_id" => content_id,
            "document_type" => Pact.like("special_route"),
            "schema_name" => Pact.like("special_route"),
            "publishing_app" => Pact.like("publisher"),
            "rendering_app" => Pact.like("frontend"),
            "locale" => Pact.like("en"),
            "routes" => Pact.like([{}]),
            "details" => Pact.like({}),
            "publication_state" => "draft",
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.get_content(content_id, version: 2)
    end

    it "responds with 200 and the published content item when requesting the published version" do
      publishing_api
        .given("a content item exists in with a superseded version with content_id: #{content_id}")
        .upon_receiving("a request to return the published content item")
        .with(
          method: :get,
          path: "/v2/content/#{content_id}",
          query: "version=2",
          headers: GdsApi::JsonClient.default_request_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 200,
          body: {
            "content_id" => content_id,
            "document_type" => Pact.like("special_route"),
            "schema_name" => Pact.like("special_route"),
            "publishing_app" => Pact.like("publisher"),
            "rendering_app" => Pact.like("frontend"),
            "locale" => Pact.like("en"),
            "routes" => Pact.like([{}]),
            "public_updated_at" => Pact.like("2015-07-30T13:58:11.000Z"),
            "details" => Pact.like({}),
            "publication_state" => "published",
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.get_content(content_id, version: 2)
    end

    it "responds with 200 and the published content item when requesting no specific version" do
      publishing_api
        .given("a content item exists in with a superseded version with content_id: #{content_id}")
        .upon_receiving("a request to return the content item")
        .with(
          method: :get,
          path: "/v2/content/#{content_id}",
          headers: GdsApi::JsonClient.default_request_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 200,
          body: {
            "content_id" => content_id,
            "document_type" => Pact.like("special_route"),
            "schema_name" => Pact.like("special_route"),
            "publishing_app" => Pact.like("publisher"),
            "rendering_app" => Pact.like("frontend"),
            "locale" => Pact.like("en"),
            "routes" => Pact.like([{}]),
            "public_updated_at" => Pact.like("2015-07-30T13:58:11.000Z"),
            "details" => Pact.like({}),
            "publication_state" => "published",
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.get_content(content_id)
    end

    it "responds with 404 when requesting a non-existent item" do
      publishing_api
        .given("no content exists")
        .upon_receiving("a request for a non-existent content item")
        .with(
          method: :get,
          path: "/v2/content/#{content_id}",
          headers: GdsApi::JsonClient.default_request_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 404,
          body: {
            "error" => {
              "code" => 404,
              "message" => Pact.term(generate: "not found", matcher: /\S+/),
            },
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      assert_raises(GdsApi::HTTPNotFound) do
        api_client.get_content(content_id)
      end
    end
  end

  describe "#get_live_content" do
    it "returns the published content item when the latest version of the content item is published" do
      publishing_api
        .given("a published content item exists with content_id: #{content_id}")
        .upon_receiving("a request to return the live content item")
        .with(
          method: :get,
          path: "/v2/content/#{content_id}",
          headers: GdsApi::JsonClient.default_request_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 200,
          body: {
            "content_id" => content_id,
            "document_type" => Pact.like("special_route"),
            "schema_name" => Pact.like("special_route"),
            "publishing_app" => Pact.like("publisher"),
            "rendering_app" => Pact.like("frontend"),
            "locale" => Pact.like("en"),
            "routes" => Pact.like([{}]),
            "public_updated_at" => Pact.like("2015-07-30T13:58:11.000Z"),
            "details" => Pact.like({}),
            "state_history" => { "1" => "published" },
            "publication_state" => "published",
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.get_live_content(content_id)
    end

    it "responds with NoLiveVersion when the content item has never been live" do
      publishing_api
        .given("a draft content item exists with content_id: #{content_id}")
        .upon_receiving("a request to return the live content item")
        .with(
          method: :get,
          path: "/v2/content/#{content_id}",
          headers: GdsApi::JsonClient.default_request_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 200,
          body: {
            "content_id" => content_id,
            "document_type" => Pact.like("special_route"),
            "schema_name" => Pact.like("special_route"),
            "publishing_app" => Pact.like("publisher"),
            "rendering_app" => Pact.like("frontend"),
            "locale" => Pact.like("en"),
            "routes" => Pact.like([{}]),
            "details" => Pact.like({}),
            "state_history" => { "1" => "draft" },
            "publication_state" => "draft",
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      assert_raises(GdsApi::PublishingApi::NoLiveVersion) do
        api_client.get_live_content(content_id)
      end
    end

    it "returns the live content item when there is a draft version of live content" do
      publishing_api
        .given("a published content item exists with a draft edition for content_id: #{content_id}")
        .upon_receiving("a request to return the content item")
        .with(
          method: :get,
          path: "/v2/content/#{content_id}",
          query: "locale=en",
          headers: GdsApi::JsonClient.default_request_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 200,
          body: {
            "content_id" => content_id,
            "document_type" => Pact.like("special_route"),
            "schema_name" => Pact.like("special_route"),
            "publishing_app" => Pact.like("publisher"),
            "rendering_app" => Pact.like("frontend"),
            "locale" => Pact.like("en"),
            "routes" => Pact.like([{}]),
            "details" => Pact.like({}),
            "state_history" => { "1" => "published", "2" => "draft" },
            "publication_state" => "draft",
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )
        .upon_receiving("a request to return the live content item")
        .with(
          method: :get,
          path: "/v2/content/#{content_id}",
          query: "locale=en&version=1",
          headers: GdsApi::JsonClient.default_request_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 200,
          body: {
            "content_id" => content_id,
            "document_type" => Pact.like("special_route"),
            "schema_name" => Pact.like("special_route"),
            "publishing_app" => Pact.like("publisher"),
            "rendering_app" => Pact.like("frontend"),
            "locale" => Pact.like("en"),
            "routes" => Pact.like([{}]),
            "public_updated_at" => Pact.like("2015-07-30T13:58:11.000Z"),
            "details" => Pact.like({}),
            "state_history" => { "1" => "published", "2" => "draft" },
            "publication_state" => "published",
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.get_live_content(content_id)
    end

    it "returns the unpublished content item when the latest version of the content item is unpublished" do
      publishing_api
        .given("an unpublished content item exists with content_id: #{content_id}")
        .upon_receiving("a request to return the content item")
        .with(
          method: :get,
          path: "/v2/content/#{content_id}",
          headers: GdsApi::JsonClient.default_request_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 200,
          body: {
            "content_id" => content_id,
            "document_type" => Pact.like("special_route"),
            "schema_name" => Pact.like("special_route"),
            "publishing_app" => Pact.like("publisher"),
            "rendering_app" => Pact.like("frontend"),
            "locale" => Pact.like("en"),
            "routes" => Pact.like([{}]),
            "public_updated_at" => Pact.like("2015-07-30T13:58:11.000Z"),
            "details" => Pact.like({}),
            "state_history" => { "1" => "unpublished" },
            "publication_state" => "unpublished",
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.get_live_content(content_id)
    end
  end

  describe "#republish" do
    it "responds with 200 if the republish command succeeds" do
      publishing_api
        .given("an unpublished content item exists with content_id: #{content_id}")
        .upon_receiving("a republish request")
        .with(
          method: :post,
          path: "/v2/content/#{content_id}/republish",
          body: {},
          headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 200,
        )

      api_client.republish(content_id)
    end

    it "responds with 404 if the content item does not exist" do
      publishing_api
        .given("no content exists")
        .upon_receiving("a republish request")
        .with(
          method: :post,
          path: "/v2/content/#{content_id}/republish",
          body: {},
          headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 404,
        )

      assert_raises(GdsApi::HTTPNotFound) do
        api_client.republish(content_id)
      end
    end

    describe "optimistic locking" do
      it "responds with 200 OK if the content item has not changed since it was requested" do
        publishing_api
          .given("the published content item #{content_id} is at version 3")
          .upon_receiving("a republish request for version 3")
          .with(
            method: :post,
            path: "/v2/content/#{content_id}/republish",
            body: {
              previous_version: 3,
            },
            headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 200,
          )

        api_client.republish(content_id, previous_version: 3)
      end

      it "responds with 409 Conflict if the content item has changed in the meantime" do
        publishing_api
          .given("the published content item #{content_id} is at version 3")
          .upon_receiving("a republish request for version 2")
          .with(
            method: :post,
            path: "/v2/content/#{content_id}/republish",
            body: {
              previous_version: 2,
            },
            headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 409,
            body: {
              "error" => {
                "code" => 409,
                "message" => Pact.term(generate: "Conflict", matcher: /\S+/),
                "fields" => {
                  "previous_version" => Pact.each_like("does not match", min: 1),
                },
              },
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

        assert_raises(GdsApi::HTTPConflict) do
          api_client.republish(content_id, previous_version: 2)
        end
      end
    end
  end

  describe "#publish" do
    it "responds with 200 if the publish command succeeds" do
      publishing_api
        .given("a draft content item exists with content_id: #{content_id}")
        .upon_receiving("a publish request")
        .with(
          method: :post,
          path: "/v2/content/#{content_id}/publish",
          body: {
            update_type: "major",
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 200,
        )

      api_client.publish(content_id, "major")
    end

    it "responds with 404 if the content item does not exist" do
      publishing_api
        .given("no content exists")
        .upon_receiving("a publish request")
        .with(
          method: :post,
          path: "/v2/content/#{content_id}/publish",
          body: {
            update_type: "major",
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 404,
        )

      assert_raises(GdsApi::HTTPNotFound) do
        api_client.publish(content_id, "major")
      end
    end

    it "responds with 422 if the update information is invalid" do
      publishing_api
        .given("a draft content item exists with content_id: #{content_id}")
        .upon_receiving("an invalid publish request")
        .with(
          method: :post,
          path: "/v2/content/#{content_id}/publish",
          body: {
            "update_type" => "",
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 422,
          body: {
            "error" => {
              "code" => 422,
              "message" => Pact.term(generate: "Unprocessable entity", matcher: /\S+/),
              "fields" => {
                "update_type" => Pact.each_like("is required", min: 1),
              },
            },
          },
        )

      assert_raises(GdsApi::HTTPUnprocessableEntity) do
        api_client.publish(content_id, "")
      end
    end

    it "responds with 409 if the content item is already published" do
      publishing_api
        .given("a published content item exists with content_id: #{content_id}")
        .upon_receiving("a publish request")
        .with(
          method: :post,
          path: "/v2/content/#{content_id}/publish",
          body: {
            update_type: "major",
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 409,
          body: {
            "error" => {
              "code" => 409, "message" => Pact.term(generate: "Cannot publish an already published content item", matcher: /\S+/)
            },
          },
        )

      assert_raises(GdsApi::HTTPConflict) do
        api_client.publish(content_id, "major")
      end
    end

    it "responds with 200 if the update information contains a locale" do
      publishing_api
        .given("a draft content item exists with content_id: #{content_id} and locale: fr")
        .upon_receiving("a publish request")
        .with(
          method: :post,
          path: "/v2/content/#{content_id}/publish",
          body: {
            update_type: "major",
            locale: "fr",
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 200,
        )

      api_client.publish(content_id, "major", locale: "fr")
    end

    describe "optimistic locking" do
      it "responds with 200 OK if the content item has not changed since it was requested" do
        publishing_api
          .given("the content item #{content_id} is at version 3")
          .upon_receiving("a publish request for version 3")
          .with(
            method: :post,
            path: "/v2/content/#{content_id}/publish",
            body: {
              update_type: "minor",
              previous_version: 3,
            },
            headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 200,
          )

        api_client.publish(content_id, "minor", previous_version: 3)
      end

      it "responds with 409 Conflict if the content item has changed in the meantime" do
        publishing_api
          .given("the content item #{content_id} is at version 3")
          .upon_receiving("a publish request for version 2")
          .with(
            method: :post,
            path: "/v2/content/#{content_id}/publish",
            body: {
              update_type: "minor",
              previous_version: 2,
            },
            headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 409,
            body: {
              "error" => {
                "code" => 409,
                "message" => Pact.term(generate: "Conflict", matcher: /\S+/),
                "fields" => {
                  "previous_version" => Pact.each_like("does not match", min: 1),
                },
              },
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

        assert_raises(GdsApi::HTTPConflict) do
          api_client.publish(content_id, "minor", previous_version: 2)
        end
      end
    end
  end

  describe "#unpublish" do
    it "responds with 200 if the unpublish command succeeds" do
      publishing_api
        .given("a published content item exists with content_id: #{content_id}")
        .upon_receiving("an unpublish request")
        .with(
          method: :post,
          path: "/v2/content/#{content_id}/unpublish",
          body: {
            type: "gone",
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 200,
        )

      api_client.unpublish(content_id, type: "gone")
    end

    it "responds with 404 if the content item does not exist" do
      publishing_api
        .given("no content exists")
        .upon_receiving("an unpublish request")
        .with(
          method: :post,
          path: "/v2/content/#{content_id}/unpublish",
          body: {
            type: "gone",
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 404,
        )

      assert_raises(GdsApi::HTTPNotFound) do
        api_client.unpublish(content_id, type: "gone")
      end
    end

    it "responds with 422 if the type is incorrect" do
      publishing_api
        .given("a published content item exists with content_id: #{content_id}")
        .upon_receiving("an invalid unpublish request")
        .with(
          method: :post,
          path: "/v2/content/#{content_id}/unpublish",
          body: {
            type: "not-a-valid-type",
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 422,
          body: {
            "error" => {
              "code" => 422,
              "message" => Pact.term(generate: "not-a-valid-type is not a valid unpublishing type", matcher: /\S+/),
              "fields" => {},
            },
          },
        )

      assert_raises(GdsApi::HTTPUnprocessableEntity) do
        api_client.unpublish(content_id, type: "not-a-valid-type")
      end
    end

    it "responds with 200 and updates the unpublishing if the content item is already unpublished" do
      publishing_api
        .given("an unpublished content item exists with content_id: #{content_id}")
        .upon_receiving("an unpublish request")
        .with(
          method: :post,
          path: "/v2/content/#{content_id}/unpublish",
          body: {
            type: "gone",
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
            "Authorization" => "Bearer #{bearer_token}",
          ),
        )
        .will_respond_with(
          status: 200,
        )

      api_client.unpublish(content_id, type: "gone")
    end

    describe "optimistic locking" do
      it "responds with 200 OK if the content item has not changed since it was requested" do
        publishing_api
          .given("the published content item #{content_id} is at version 3")
          .upon_receiving("an unpublish request for version 3")
          .with(
            method: :post,
            path: "/v2/content/#{content_id}/unpublish",
            body: {
              type: "gone",
              previous_version: 3,
            },
            headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 200,
          )

        api_client.unpublish(content_id, type: "gone", previous_version: 3)
      end

      it "responds with 409 Conflict if the content item has changed in the meantime" do
        publishing_api
          .given("the published content item #{content_id} is at version 3")
          .upon_receiving("an unpublish request for version 2")
          .with(
            method: :post,
            path: "/v2/content/#{content_id}/unpublish",
            body: {
              type: "gone",
              previous_version: 2,
            },
            headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 409,
            body: {
              "error" => {
                "code" => 409,
                "message" => Pact.term(generate: "Conflict", matcher: /\S+/),
                "fields" => {
                  "previous_version" => Pact.each_like("does not match", min: 1),
                },
              },
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

        assert_raises(GdsApi::HTTPConflict) do
          api_client.unpublish(content_id, type: "gone", previous_version: 2)
        end
      end
    end
  end

  describe "#patch_links" do
    it "replaces the links and responds with the new links when setting links of the same type" do
      publishing_api
        .given("organisation links exist for content_id #{content_id}")
        .upon_receiving("a patch organisation links request")
        .with(
          method: :patch,
          path: "/v2/links/#{content_id}",
          body: {
            links: {
              organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
            },
          },
          headers: {
            "Content-Type" => "application/json",
          },
        )
        .will_respond_with(
          status: 200,
          body: {
            links: {
              organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
            },
          },
        )

      api_client.patch_links(
        content_id,
        links: {
          organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
        },
      )
    end

    it "adds the new type of links and responds with the whole link set when setting links of a different type" do
      publishing_api
        .given("organisation links exist for content_id #{content_id}")
        .upon_receiving("a patch topic links request")
        .with(
          method: :patch,
          path: "/v2/links/#{content_id}",
          body: {
            links: {
              topics: %w[225df4a8-2945-4e9b-8799-df7424a90b69],
            },
          },
          headers: {
            "Content-Type" => "application/json",
          },
        )
        .will_respond_with(
          status: 200,
          body: {
            links: {
              topics: %w[225df4a8-2945-4e9b-8799-df7424a90b69],
              organisations: %w[20583132-1619-4c68-af24-77583172c070],
            },
          },
        )

      api_client.patch_links(
        content_id,
        links: {
          topics: %w[225df4a8-2945-4e9b-8799-df7424a90b69],
        },
      )
    end

    it "responds with the links when deleting links of a specific type" do
      publishing_api
        .given("organisation links exist for content_id #{content_id}")
        .upon_receiving("a patch blank organisation links request")
        .with(
          method: :patch,
          path: "/v2/links/#{content_id}",
          body: {
            links: {
              organisations: [],
            },
          },
          headers: {
            "Content-Type" => "application/json",
          },
        )
        .will_respond_with(
          status: 200,
          body: {
            links: {},
          },
        )

      api_client.patch_links(
        content_id,
        links: {
          organisations: [],
        },
      )
    end

    it "responds with the links when there's no links entry" do
      publishing_api
        .given("no links exist for content_id #{content_id}")
        .upon_receiving("a patch organisation links request")
        .with(
          method: :patch,
          path: "/v2/links/#{content_id}",
          body: {
            links: {
              organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
            },
          },
          headers: {
            "Content-Type" => "application/json",
          },
        )
        .will_respond_with(
          status: 200,
          body: {
            links: {
              organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
            },
          },
        )

      api_client.patch_links(
        content_id,
        links: {
          organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
        },
      )
    end

    describe "optimistic locking" do
      it "responds with 200 OK if the linkset has not changed since it was requested" do
        publishing_api
          .given("the linkset for #{content_id} is at version 3")
          .upon_receiving("a request to update the linkset at version 3")
          .with(
            method: :patch,
            path: "/v2/links/#{content_id}",
            body: {
              links: {
                organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
              },
              previous_version: 3,
            },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200,
          )

        api_client.patch_links(
          content_id,
          links: {
            organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
          },
          previous_version: 3,
        )
      end

      it "responds with 409 Conflict if the content item has changed in the meantime" do
        publishing_api
            .given("the linkset for #{content_id} is at version 3")
            .upon_receiving("a request to update the linkset at version 2")
            .with(
              method: :patch,
              path: "/v2/links/#{content_id}",
              body: {
                links: {
                  organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
                },
                previous_version: 2,
              },
              headers: {
                "Content-Type" => "application/json",
              },
            )
            .will_respond_with(
              status: 409,
              body: {
                "error" => {
                  "code" => 409,
                  "message" => Pact.term(generate: "Conflict", matcher: /\S+/),
                  "fields" => {
                    "previous_version" => Pact.each_like("does not match", min: 1),
                  },
                },
              },
              headers: {
                "Content-Type" => "application/json; charset=utf-8",
              },
            )

        assert_raises(GdsApi::HTTPConflict) do
          api_client.patch_links(
            content_id,
            links: {
              organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
            },
            previous_version: 2,
          )
        end
      end
    end

    describe "#get_linkables" do
      let(:linkables) do
        [
          {
            "title" => "Content Item A",
            "internal_name" => "an internal name",
            "content_id" => "aaaaaaaa-aaaa-1aaa-aaaa-aaaaaaaaaaaa",
            "publication_state" => "draft",
            "base_path" => "/a-base-path",
          },
          {
            "title" => "Content Item B",
            "internal_name" => "Content Item B",
            "content_id" => "bbbbbbbb-bbbb-2bbb-bbbb-bbbbbbbbbbbb",
            "publication_state" => "published",
            "base_path" => "/another-base-path",
          },
        ]
      end

      it "returns the content items of a given document_type" do
        publishing_api
          .given("there is content with document_type 'topic'")
          .upon_receiving("a get linkables request")
          .with(
            method: :get,
            path: "/v2/linkables",
            query: "document_type=topic",
            headers: GdsApi::JsonClient.default_request_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 200,
            body: linkables,
          )

        api_client.get_linkables(document_type: "topic")
      end
    end

    describe "#get_links_changes" do
      let(:link_changes) do
        { "link_changes" => [
          {
            "source" => { "title" => "Edition Title A1",
                          "base_path" => "/base/path/a1",
                          "content_id" => "aaaaaaaa-aaaa-1aaa-aaaa-aaaaaaaaaaaa" },
            "target" => { "title" => "Edition Title B1",
                          "base_path" => "/base/path/b1",
                          "content_id" => "bbbbbbbb-bbbb-1bbb-bbbb-bbbbbbbbbbbb" },
            "link_type" => "taxons",
            "change" => "add",
            "user_uid" => "11111111-1111-1111-1111-111111111111",
            "created_at" => "2017-01-01T09:00:00.100Z",
          },
          {
            "source" => { "title" => "Edition Title A2",
                          "base_path" => "/base/path/a2",
                          "content_id" => "aaaaaaaa-aaaa-2aaa-aaaa-aaaaaaaaaaaa" },
            "target" => { "title" => "Edition Title B2",
                          "base_path" => "/base/path/b2",
                          "content_id" => "bbbbbbbb-bbbb-2bbb-bbbb-bbbbbbbbbbbb" },
            "link_type" => "taxons",
            "change" => "remove",
            "user_uid" => "22222222-2222-2222-2222-222222222222",
            "created_at" => "2017-01-01T09:00:00.100Z",
          },
        ] }
      end

      it "returns the changes for a single link_type" do
        publishing_api
          .given("there are two link changes with a link_type of 'taxons'")
          .upon_receiving("a get links changes request for changes with a link_type of 'taxons'")
          .with(
            method: :get,
            path: "/v2/links/changes",
            query: "link_types%5B%5D=taxons",
            headers: GdsApi::JsonClient.default_request_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 200,
            body: link_changes,
          )

        api_client.get_links_changes(link_types: %w[taxons])
      end
    end

    describe "#get_paged_content_items" do
      it "returns two content items" do
        publishing_api
          .given("there are four content items with document_type 'topic'")
          .upon_receiving("get the first page request")
          .with(
            method: :get,
            path: "/v2/content",
            query: "document_type=topic&fields%5B%5D=title&fields%5B%5D=base_path&page=1&per_page=2",
            headers: GdsApi::JsonClient.default_request_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 200,
            body: {
              total: 4,
              pages: 2,
              current_page: 1,
              links: [{ href: "http://example.org/v2/content?document_type=topic&fields%5B%5D=title&fields%5B%5D=base_path&per_page=2&page=2",
                        rel: "next" },
                      { href: "http://example.org/v2/content?document_type=topic&fields%5B%5D=title&fields%5B%5D=base_path&per_page=2&page=1",
                        rel: "self" }],
              results: [
                { title: "title_1", base_path: "/path_1" },
                { title: "title_2", base_path: "/path_2" },
              ],
            },
          )
        publishing_api
          .given("there are four content items with document_type 'topic'")
          .upon_receiving("get the second page request")
          .with(
            method: :get,
            path: "/v2/content",
            query: "document_type=topic&fields%5B%5D=title&fields%5B%5D=base_path&page=2&per_page=2",
            headers: GdsApi::JsonClient.default_request_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 200,
            body: {
              total: 4,
              pages: 2,
              current_page: 2,
              links: [{ href: "http://example.org/v2/content?document_type=topic&fields%5B%5D=title&fields%5B%5D=base_path&per_page=2&page=1",
                        rel: "previous" },
                      { href: "http://example.org/v2/content?document_type=topic&fields%5B%5D=title&fields%5B%5D=base_path&per_page=2&page=2",
                        rel: "self" }],
              results: [
                { title: "title_3", base_path: "/path_3" },
                { title: "title_4", base_path: "/path_4" },
              ],
            },
          )
        assert_equal(
          api_client.get_content_items_enum(document_type: "topic", fields: %i[title base_path], per_page: 2).to_a,
          [
            { "title" => "title_1", "base_path" => "/path_1" },
            { "title" => "title_2", "base_path" => "/path_2" },
            { "title" => "title_3", "base_path" => "/path_3" },
            { "title" => "title_4", "base_path" => "/path_4" },
          ],
        )
      end
    end

    describe "#get_content_items" do
      it "returns the content items of a certain document_type" do
        publishing_api
          .given("there is content with document_type 'topic'")
          .upon_receiving("a get entries request")
          .with(
            method: :get,
            path: "/v2/content",
            query: "document_type=topic&fields%5B%5D=title&fields%5B%5D=base_path",
            headers: GdsApi::JsonClient.default_request_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 200,
            body: {
              total: 2,
              pages: 1,
              current_page: 1,
              links: [{
                href: "http://example.org/v2/content?document_type=topic&fields%5B%5D=title&fields%5B%5D=base_path&page=1",
                rel: "self",
              }],
              results: [
                { title: "Content Item A", base_path: "/a-base-path" },
                { title: "Content Item B", base_path: "/another-base-path" },
              ],
            },
          )

        api_client.get_content_items(
          document_type: "topic",
          fields: %i[title base_path],
        )
      end

      it "returns the content items in english locale by default" do
        publishing_api
          .given("a content item exists in multiple locales with content_id: #{content_id}")
          .upon_receiving("a get entries request")
          .with(
            method: :get,
            path: "/v2/content",
            query: "document_type=topic&fields%5B%5D=content_id&fields%5B%5D=locale",
            headers: GdsApi::JsonClient.default_request_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 200,
            body: {
              total: 1,
              pages: 1,
              current_page: 1,
              links: [{
                href: "http://example.org/v2/content?document_type=topic&fields%5B%5D=content_id&fields%5B%5D=locale&page=1",
                rel: "self",
              }],
              results: [
                { content_id: content_id, locale: "en" },
              ],
            },
          )

        api_client.get_content_items(
          document_type: "topic",
          fields: %i[content_id locale],
        )
      end

      it "returns the content items in a specific locale" do
        publishing_api
          .given("a content item exists in multiple locales with content_id: #{content_id}")
          .upon_receiving("a get entries request with a specific locale")
          .with(
            method: :get,
            path: "/v2/content",
            query: "document_type=topic&fields%5B%5D=content_id&fields%5B%5D=locale&locale=fr",
            headers: GdsApi::JsonClient.default_request_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 200,
            body: {
              total: 1,
              pages: 1,
              current_page: 1,
              links: [{
                href: "http://example.org/v2/content?document_type=topic&fields%5B%5D=content_id&fields%5B%5D=locale&locale=fr&page=1",
                rel: "self",
              }],
              results: [
                { content_id: content_id, locale: "fr" },
              ],
            },
          )

        api_client.get_content_items(
          document_type: "topic",
          fields: %i[content_id locale],
          locale: "fr",
        )
      end

      it "returns the content items in all the available locales" do
        publishing_api
          .given("a content item exists in multiple locales with content_id: #{content_id}")
          .upon_receiving("a get entries request with an 'all' locale")
          .with(
            method: :get,
            path: "/v2/content",
            query: "document_type=topic&fields%5B%5D=content_id&fields%5B%5D=locale&locale=all",
            headers: GdsApi::JsonClient.default_request_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 200,
            body: {
              total: 3,
              pages: 1,
              current_page: 1,
              links: [{
                href: "http://example.org/v2/content?document_type=topic&fields%5B%5D=content_id&fields%5B%5D=locale&locale=all&page=1",
                rel: "self",
              }],
              results: [
                { content_id: content_id, locale: "en" },
                { content_id: content_id, locale: "fr" },
                { content_id: content_id, locale: "ar" },
              ],
            },
          )

        api_client.get_content_items(
          document_type: "topic",
          fields: %i[content_id locale],
          locale: "all",
        )
      end

      it "returns details hashes" do
        publishing_api
          .given("a content item exists with content_id: #{content_id} and it has details")
          .upon_receiving("a get entries request with details field")
          .with(
            method: :get,
            path: "/v2/content",
            query: "document_type=topic&fields%5B%5D=content_id&fields%5B%5D=details",
            headers: GdsApi::JsonClient.default_request_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 200,
            body: {
              total: 1,
              pages: 1,
              current_page: 1,
              links: [{
                href: "http://example.org/v2/content?document_type=topic&fields%5B%5D=content_id&fields%5B%5D=details&page=1",
                rel: "self",
              }],
              results: [
                { content_id: content_id, details: { foo: :bar } },
              ],
            },
          )

        api_client.get_content_items(
          document_type: "topic",
          fields: %i[content_id details],
        )
      end

      it "returns the items matching a query" do
        publishing_api
          .given("there is content with document_type 'topic'")
          .upon_receiving("a get entries request with search_in and q parameters")
          .with(
            method: :get,
            path: "/v2/content",
            query: "document_type=topic&fields%5B%5D=content_id&q=an+internal+name&search_in%5B%5D=details.internal_name",
            headers: GdsApi::JsonClient.default_request_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 200,
            body: {
              total: 1,
              pages: 1,
              current_page: 1,
              links: [{
                href: "http://example.org/v2/content?document_type=topic&fields%5B%5D=content_id&q=an+internal+name&search_in%5B%5D=details.internal_name&page=1",
                rel: "self",
              }],
              results: [
                { content_id: "aaaaaaaa-aaaa-1aaa-aaaa-aaaaaaaaaaaa" },
              ],
            },
          )

        api_client.get_content_items(
          document_type: "topic",
          fields: [:content_id],
          q: "an internal name",
          search_in: ["details.internal_name"],
        )
      end
    end

    describe "#discard_draft(content_id, options = {})" do
      it "responds with 200 when the content item exists" do
        publishing_api
          .given("a content item exists with content_id: #{content_id}")
          .upon_receiving("a request to discard draft content")
          .with(
            method: :post,
            path: "/v2/content/#{content_id}/discard-draft",
            body: {},
            headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 200,
          )

        api_client.discard_draft(content_id)
      end

      it "responds with 200 when the content item exists and is French" do
        publishing_api
          .given("a French content item exists with content_id: #{content_id}")
          .upon_receiving("a request to discard French draft content")
          .with(
            method: :post,
            path: "/v2/content/#{content_id}/discard-draft",
            body: {
              locale: "fr",
            },
            headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 200,
          )

        api_client.discard_draft(content_id, locale: "fr")
      end

      it "responds with a 404 when there is no content with that content_id" do
        publishing_api
          .given("no content exists")
          .upon_receiving("a request to discard draft content")
          .with(
            method: :post,
            path: "/v2/content/#{content_id}/discard-draft",
            body: {},
            headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 404,
          )

        assert_raises(GdsApi::HTTPNotFound) do
          api_client.discard_draft(content_id)
        end
      end
    end

    describe "#get_links_by_content_id" do
      it "returns the links for some content_ids" do
        content_id_with_links = "bed722e6-db68-43e5-9079-063f623335a7"
        content_id_no_links = "f40a63ce-ac0c-4102-84d1-f1835cb7daac"

        response_hash = {
          content_id_with_links => {
            "links" => {
              "taxons" => %w[20583132-1619-4c68-af24-77583172c070],
            },
            "version" => 2,
          },
          content_id_no_links => {
            "links" => {},
            "version" => 0,
          },
        }

        publishing_api
          .given("taxon links exist for content_id bed722e6-db68-43e5-9079-063f623335a7")
          .upon_receiving("a bulk_links request")
          .with(
            method: :post,
            path: "/v2/links/by-content-id",
            body: {
              content_ids: [content_id_with_links, content_id_no_links],
            },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200,
            body: response_hash,
          )

        api_client.get_links_for_content_ids([content_id_with_links, content_id_no_links])
      end
    end

    describe "#get_linked_items" do
      it "404s if the content item does not exist" do
        publishing_api
          .given("no content exists")
          .upon_receiving("a request to return the items linked to it")
          .with(
            method: :get,
            path: "/v2/linked/#{content_id}",
            query: "fields%5B%5D=content_id&fields%5B%5D=base_path&link_type=topic",
            headers: GdsApi::JsonClient.default_request_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 404,
            body: {
              "error" => {
                "code" => 404,
                "message" => Pact.term(generate: "not found", matcher: /\S+/),
              },
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

        assert_raises(GdsApi::HTTPNotFound) do
          api_client.get_linked_items(
            content_id,
            link_type: "topic",
            fields: %w[content_id base_path],
          )
        end
      end

      describe "there are two documents that link to the wanted document" do
        let(:linked_content_item) { content_item_for_content_id("6cb2cf8c-670f-4de3-97d5-6ad9114581c7") }

        let(:linking_content_item1) do
          content_item_for_content_id(
            "e2961462-bc37-48e9-bb98-c981ef1a2d59",
            "base_path" => "/item-b",
            "links" => {
              "topic" => [linked_content_item["content_id1"]],
            },
          )
        end

        let(:linking_content_item2) do
          content_item_for_content_id(
            "08dfd5c3-d935-4e81-88fd-cfe65b78893d",
            "base_path" => "/item-a",
            "links" => {
              "topic" => [linked_content_item["content_id1"]],
            },
          )
        end

        before do
          publishing_api
            .given("there are two documents with a 'topic' link to another document")
            .upon_receiving("a get linked request")
            .with(
              method: :get,
              path: "/v2/linked/#{linked_content_item['content_id']}",
              query: "fields%5B%5D=content_id&fields%5B%5D=base_path&link_type=topic",
              headers: GdsApi::JsonClient.default_request_headers.merge(
                "Authorization" => "Bearer #{bearer_token}",
              ),
            )
            .will_respond_with(
              status: 200,
              body: [
                {
                  content_id: linking_content_item1["content_id"],
                  base_path: linking_content_item1["base_path"],
                },
                {
                  content_id: linking_content_item2["content_id"],
                  base_path: linking_content_item2["base_path"],
                },
              ],
            )
        end

        it "returns the requested fields of linking items" do
          response = api_client.get_linked_items(
            linked_content_item["content_id"],
            link_type: "topic",
            fields: %w[content_id base_path],
          )
          assert_equal 200, response.code

          expected_documents = [
            { "content_id" => linking_content_item2["content_id"], "base_path" => "/item-a" },
            { "content_id" => linking_content_item1["content_id"], "base_path" => "/item-b" },
          ]

          expected_documents.each do |document|
            assert_includes response.to_a, document
          end
        end
      end
    end

    describe "#get_editions" do
      it "responds correctly when there are editions available to paginate over" do
        publishing_api
          .given("there are live content items with base_paths /foo and /bar")
          .upon_receiving("a get editions request")
          .with(
            method: :get,
            path: "/v2/editions",
            query: "fields%5B%5D=content_id",
            headers: GdsApi::JsonClient.default_request_headers.merge(
              "Authorization" => "Bearer #{bearer_token}",
            ),
          )
          .will_respond_with(
            status: 200,
            body: {
              results: [
                { content_id: "08f86d00-e95f-492f-af1d-470c5ba4752e" },
                { content_id: "ca6c58a6-fb9d-479d-b3e6-74908781cb18" },
              ],
              links: [
                { href: "http://example.org/v2/editions?fields%5B%5D=content_id", rel: "self" },
              ],
            },
          )

        api_client.get_editions(fields: %w[content_id])
      end
    end

    describe "#get_paged_editions" do
      describe "there are multiple pages of editions" do
        let(:content_id_1) { "bd50a6d9-f03d-4ccf-94aa-ad79579990a9" }
        let(:content_id_2) { "989033fe-252a-4e69-976d-5c0059bca949" }
        let(:content_id_3) { "271d4270-9186-4d60-b2ca-1d7dae7e0f73" }
        let(:content_id_4) { "638af19c-27fc-4cc9-a914-4cca49028688" }

        let(:first_page) do
          {
            request: {
              method: :get,
              path: "/v2/editions",
              query: "fields%5B%5D=content_id&per_page=2",
              headers: GdsApi::JsonClient.default_request_headers.merge(
                "Authorization" => "Bearer #{bearer_token}",
              ),
            },
            response: {
              status: 200,
              body: {
                results: [
                  { content_id: content_id_1 },
                  { content_id: content_id_2 },
                ],
                links: [
                  { href: "http://example.org#{second_page[:request][:path]}?#{second_page[:request][:query]}", rel: "next" },
                  { href: "http://example.org/v2/editions?fields%5B%5D=content_id&per_page=2", rel: "self" },
                ],
              },
            },
          }
        end

        let(:second_page) do
          {
            request: {
              method: :get,
              path: "/v2/editions",
              query: "fields%5B%5D=content_id&per_page=2&after=2017-02-01T00%3A00%3A00.000000Z%2C2",
              headers: GdsApi::JsonClient.default_request_headers.merge(
                "Authorization" => "Bearer #{bearer_token}",
              ),
            },
            response: {
              status: 200,
              body: {
                results: [
                  { content_id: content_id_3 },
                  { content_id: content_id_4 },
                ],
                links: [
                  { href: "http://example.org/v2/editions?fields%5B%5D=content_id&per_page=2&after=2017-02-01T00%3A00%3A00.000000Z%2C2", rel: "self" },
                  { href: "http://example.org/v2/editions?fields%5B%5D=content_id&per_page=2&before=2017-03-01T00%3A00%3A00.000000Z%2C3", rel: "previous" },
                ],
              },
            },
          }
        end

        before do
          publishing_api
            .given("there are 4 live content items with fixed updated timestamps")
            .upon_receiving("a get editions request for 2 per page")
            .with(first_page[:request])
            .will_respond_with(first_page[:response])

          publishing_api
            .given("there are 4 live content items with fixed updated timestamps")
            .upon_receiving("a next page editions request")
            .with(second_page[:request])
            .will_respond_with(second_page[:response])
        end

        it "receives two pages of results" do
          first_page_url = "#{publishing_api_host}#{first_page[:request][:path]}?#{first_page[:request][:query]}"
          second_page_path = "#{second_page[:request][:path]}?#{second_page[:request][:query]}"

          # Manually override JsonClient#get_json, because the Pact tests mean we return an invalid pagination
          # URL, which we have to replace with our mocked publishing_api_host
          api_client
            .expects(:get_json)
            .with(first_page_url)
            .returns(GdsApi::JsonClient.new.get_json(first_page_url, first_page[:request][:headers]))

          api_client
            .expects(:get_json)
            .with("http://example.org#{second_page_path}")
            .returns(GdsApi::JsonClient.new.get_json("#{publishing_api_host}#{second_page_path}", second_page[:request][:headers]))

          response = api_client.get_paged_editions(fields: %w[content_id], per_page: 2).to_a

          assert_equal 2, response.count
          first_page_content_ids = response[0]["results"].map { |content_item| content_item["content_id"] }
          second_page_content_ids = response[1]["results"].map { |content_item| content_item["content_id"] }

          assert_equal [content_id_1, content_id_2], first_page_content_ids
          assert_equal [content_id_3, content_id_4], second_page_content_ids
        end
      end
    end

    describe "content ID validation" do
      %i[get_content get_links get_linked_items discard_draft].each do |method|
        it "happens on #{method}" do
          assert_raises ArgumentError do
            api_client.send(method, nil)
          end
        end
      end

      it "happens on publish" do
        assert_raises ArgumentError do
          api_client.publish(nil, "major")
        end
      end

      it "happens on put_content" do
        assert_raises ArgumentError do
          api_client.put_content(nil, {})
        end
      end

      it "happens on patch_links" do
        assert_raises ArgumentError do
          api_client.patch_links(nil, links: {})
        end
      end
    end

    describe "#put_path" do
      it "returns 200 if the path was successfully reserved" do
        base_path = "/test-intent"
        payload = {
          publishing_app: "publisher",
        }

        publishing_api
          .given("no content exists")
          .upon_receiving("a request to put a path")
          .with(
            method: :put,
            path: "/paths#{base_path}",
            body: payload,
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200,
            body: {},
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

        api_client.put_path(base_path, payload)
      end

      it "returns 422 if the request is invalid" do
        base_path = "/test-item"
        payload = {
          publishing_app: "whitehall",
        }

        publishing_api
          .given("/test-item has been reserved by the Publisher application")
          .upon_receiving("a request to change publishing app")
          .with(
            method: :put,
            path: "/paths#{base_path}",
            body: payload,
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 422,
            body: {
              "error" => {
                "code" => 422,
                "message" => Pact.term(generate: "Unprocessable", matcher: /\S+/),
                "fields" => {
                  "base_path" => Pact.each_like("has been reserved", min: 1),
                },
              },
            },
          )

        assert_raises(GdsApi::HTTPUnprocessableEntity) do
          api_client.put_path(base_path, payload)
        end
      end

      it "returns 200 if an existing path was overridden" do
        base_path = "/test-item"
        payload = {
          publishing_app: "whitehall",
          override_existing: "true",
        }

        publishing_api
          .given("/test-item has been reserved by the Publisher application")
          .upon_receiving("a request to change publishing app with override_existing set")
          .with(
            method: :put,
            path: "/paths#{base_path}",
            body: payload,
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200,
            body: {},
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

        api_client.put_path(base_path, payload)
      end
    end

    describe "#unreserve_path" do
      it "responds with 200 OK if reservation is owned by the app" do
        publishing_app = "publisher"
        base_path = "/test-item"

        publishing_api
          .given("/test-item has been reserved by the Publisher application")
          .upon_receiving("a request to unreserve a path")
          .with(
            method: :delete,
            path: "/paths#{base_path}",
            body: { publishing_app: publishing_app },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200,
            body: {},
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

        api_client.unreserve_path(base_path, publishing_app)
      end

      it "raises an error if the reservation does not exist" do
        publishing_app = "publisher"
        base_path = "/test-item"

        publishing_api
          .given("no content exists")
          .upon_receiving("a request to unreserve a non-existant path")
          .with(
            method: :delete,
            path: "/paths#{base_path}",
            body: { publishing_app: publishing_app },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 404,
            body: {},
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

        assert_raises(GdsApi::HTTPNotFound) do
          api_client.unreserve_path(base_path, publishing_app)
        end
      end

      it "raises an error if the reservation is with another app" do
        publishing_app = "whitehall"
        base_path = "/test-item"

        publishing_api
          .given("/test-item has been reserved by the Publisher application")
          .upon_receiving("a request to unreserve a path owned by another app")
          .with(
            method: :delete,
            path: "/paths#{base_path}",
            body: { publishing_app: "whitehall" },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 422,
            body: {},
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

        assert_raises(GdsApi::HTTPUnprocessableEntity) do
          api_client.unreserve_path(base_path, publishing_app)
        end
      end
    end

    describe "#put_intent" do
      it "responds with 200 OK if publish intent is valid" do
        base_path = "/test-intent"
        publish_intent = { publishing_app: "publisher",
                           rendering_app: "frontend",
                           publish_time: "2019-11-11t17:56:17+00:00" }

        publishing_api
          .given("no content exists")
          .upon_receiving("a request to create a publish intent")
          .with(
            method: :put,
            path: "/publish-intent#{base_path}",
            body: publish_intent,
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200,
            body: {
              "publishing_app" => "publisher",
              "rendering_app" => "frontend",
              "publish_time" => "2019-11-11t17:56:17+00:00",
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

        api_client.put_intent(base_path, publish_intent)
      end
    end

    describe "#delete_intent" do
      it "returns 200 OK if intent existed and was deleted" do
        base_path = "/test-intent"

        publishing_api
          .given("a publish intent exists at /test-intent")
          .upon_receiving("a request to delete a publish intent")
          .with(
            method: :delete,
            path: "/publish-intent#{base_path}",
          )
          .will_respond_with(
            status: 200,
            body: {},
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

        api_client.destroy_intent(base_path)
      end

      it "returns 404 Not found if the intent does not exist" do
        base_path = "/test-intent"

        publishing_api
          .given("no content exists")
          .upon_receiving("a request to delete a publish intent")
          .with(
            method: :delete,
            path: "/publish-intent#{base_path}",
          )
          .will_respond_with(
            status: 404,
            body: {},
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

        api_client.destroy_intent(base_path)
      end
    end
  end

private

  def content_item_for_content_id(content_id, attrs = {})
    {
      "base_path" => "/robots.txt",
      "content_id" => content_id,
      "title" => "Instructions for crawler robots",
      "description" => "robots.txt provides rules for which parts of GOV.UK are permitted to be crawled by different bots.",
      "schema_name" => "special_route",
      "document_type" => "special_route",
      "public_updated_at" => "2015-07-30T13:58:11.000Z",
      "publishing_app" => "static",
      "rendering_app" => "static",
      "locale" => "en",
      "routes" => [
        {
          "path" => attrs["base_path"] || "/robots.txt",
          "type" => "exact",
        },
      ],
      "update_type" => "major",
      "details" => {},
    }.merge(attrs)
  end
end
