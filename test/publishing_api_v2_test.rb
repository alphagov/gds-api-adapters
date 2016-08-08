require 'test_helper'
require 'gds_api/publishing_api_v2'
require 'json'

describe GdsApi::PublishingApiV2 do
  include PactTest

  def content_item_for_content_id(content_id, attrs = {})
    {
      "base_path" => "/robots.txt",
      "content_id" => content_id,
      "title" => "Instructions for crawler robots",
      "description" => "robots.txt provides rules for which parts of GOV.UK are permitted to be crawled by different bots.",
      "format" => "special_route",
      "public_updated_at" => "2015-07-30T13:58:11.000Z",
      "publishing_app" => "static",
      "rendering_app" => "static",
      "routes" => [
        {
          "path" => attrs["base_path"] || "/robots.txt",
          "type" => "exact"
        }
      ],
      "update_type" => "major"
    }.merge(attrs)
  end

  before do
    @base_api_url = Plek.current.find("publishing-api")
    @api_client = GdsApi::PublishingApiV2.new('http://localhost:3093')

    @content_id = "bed722e6-db68-43e5-9079-063f623335a7"
  end

  describe "#put_content" do
    describe "if the entry is valid" do
      before do
        @content_item = content_item_for_content_id(@content_id)

        publishing_api
          .given("no content exists")
          .upon_receiving("a request to create a content item without links")
          .with(
            method: :put,
            path: "/v2/content/#{@content_id}",
            body: @content_item,
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200,
          )
      end

      it "responds with 200 OK" do
        response = @api_client.put_content(@content_id, @content_item)
        assert_equal 200, response.code
      end
    end

    describe "if the path is reserved by a different app" do
      before do
        @content_item = content_item_for_content_id(@content_id, "base_path" => "/test-item", "publishing_app" => "whitehall")

        publishing_api
          .given("/test-item has been reserved by the Publisher application")
          .upon_receiving("a request from the Whitehall application to create a content item at /test-item")
          .with(
            method: :put,
            path: "/v2/content/#{@content_id}",
            body: @content_item,
            headers: {
              "Content-Type" => "application/json",
            }
          )
          .will_respond_with(
            status: 422,
            body: {
              "error" => {
                "code" => 422,
                "message" => Pact.term(generate: "Conflict", matcher:/\S+/),
                "fields" => {
                  "base_path" => Pact.each_like("is already in use by the 'publisher' app", :min => 1),
                },
              },
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8"
            }
          )
      end

      it "responds with 422 Unprocessable Entity" do
        error = assert_raises GdsApi::HTTPClientError do
          @api_client.put_content(@content_id, @content_item)
        end
        assert_equal "Conflict", error.error_details["error"]["message"]
      end
    end

    describe "with an invalid item" do
      before do
        @content_item = content_item_for_content_id(@content_id, "base_path" => "not a url path")

        publishing_api
          .given("no content exists")
          .upon_receiving("a request to create an invalid content-item")
          .with(
            method: :put,
            path: "/v2/content/#{@content_id}",
            body: @content_item,
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 422,
            body: {
              "error" => {
                "code" => 422,
                "message" => Pact.term(generate: "Unprocessable entity", matcher:/\S+/),
                "fields" => {
                  "base_path" => Pact.each_like("is invalid", :min => 1),
                },
              },
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8"
            }
          )
      end

      it "responds with 422 Unprocessable Entity" do
        error = assert_raises GdsApi::HTTPClientError do
          @api_client.put_content(@content_id, @content_item)
        end
        assert_equal 422, error.code
        assert_equal "Unprocessable entity", error.error_details["error"]["message"]
      end
    end

    describe "optimistic locking" do
      describe "if the content item has not changed since it was requested" do
        before do
          @content_item = content_item_for_content_id(@content_id, "previous_version" => 3)

          publishing_api
            .given("the content item #{@content_id} is at version 3")
            .upon_receiving("a request to update the content item at version 3")
            .with(
              method: :put,
              path: "/v2/content/#{@content_id}",
              body: @content_item,
              headers: {
                "Content-Type" => "application/json",
              },
            )
            .will_respond_with(
              status: 200,
            )
        end

        it "responds with 200 OK" do
          response = @api_client.put_content(@content_id, @content_item)
          assert_equal 200, response.code
        end
      end

      describe "if the content item has changed in the meantime" do
        before do
          @content_item = content_item_for_content_id(@content_id, "previous_version" => 2)

          publishing_api
            .given("the content item #{@content_id} is at version 3")
            .upon_receiving("a request to update the content item at version 2")
            .with(
              method: :put,
              path: "/v2/content/#{@content_id}",
              body: @content_item,
              headers: {
                "Content-Type" => "application/json",
              },
            )
            .will_respond_with(
              status: 409,
              body: {
                "error" => {
                  "code" => 409,
                  "message" => Pact.term(generate: "Conflict", matcher:/\S+/),
                  "fields" => {
                    "previous_version" => Pact.each_like("does not match", :min => 1),
                  },
                },
              },
              headers: {
                "Content-Type" => "application/json; charset=utf-8"
              }
            )
        end

        it "responds with 409 Conflict" do
          error = assert_raises GdsApi::HTTPClientError do
            @api_client.put_content(@content_id, @content_item)
          end
          assert_equal 409, error.code
          assert_equal "Conflict", error.error_details["error"]["message"]
        end
      end
    end
  end

  describe "#get_content" do
    describe "when the content item exists" do
      before do
        @content_item = content_item_for_content_id(@content_id)

        publishing_api
          .given("a content item exists with content_id: #{@content_id}")
          .upon_receiving("a request to return the content item")
          .with(
            method: :get,
            path: "/v2/content/#{@content_id}",
          )
          .will_respond_with(
            status: 200,
            body: {
              "content_id" => @content_id,
              "document_type" => Pact.like("special_route"),
              "schema_name" => Pact.like("special_route"),
              "publishing_app" => Pact.like("publisher"),
              "rendering_app" => Pact.like("frontend"),
              "locale" => Pact.like("en"),
              "routes" => Pact.like([{}]),
              "public_updated_at" => Pact.like("2015-07-30T13:58:11.000Z"),
              "details" => Pact.like({})
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )
      end

      it "responds with 200 and the content item" do
        response = @api_client.get_content(@content_id)
        assert_equal 200, response.code
        assert_equal @content_item["format"], response["document_type"]
      end
    end

    describe "when a content item exists in multiple locales" do
      before do
        @content_item = content_item_for_content_id(@content_id)

        publishing_api
          .given("a content item exists in multiple locales with content_id: #{@content_id}")
          .upon_receiving("a request to return the content item")
          .with(
            method: :get,
            path: "/v2/content/#{@content_id}",
            query: "locale=fr",
          )
          .will_respond_with(
            status: 200,
            body: {
              "content_id" => @content_id,
              "document_type" => Pact.like("special_route"),
              "schema_name" => Pact.like("special_route"),
              "publishing_app" => Pact.like("publisher"),
              "rendering_app" => Pact.like("frontend"),
              "locale" => "fr",
              "routes" => Pact.like([{}]),
              "public_updated_at" => Pact.like("2015-07-30T13:58:11.000Z"),
              "details" => Pact.like({})
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )
      end

      it "responds with 200 and the content item" do
        response = @api_client.get_content(@content_id, locale: "fr")
        assert_equal 200, response.code
        assert_equal response["locale"], "fr"
      end
    end

    describe "when a content item exists in with a superseded version" do
      describe "when requesting the superseded version" do
        before do
          @content_item = content_item_for_content_id(@content_id)

          publishing_api
            .given("a content item exists in with a superseded version with content_id: #{@content_id}")
            .upon_receiving("a request to return the superseded content item")
            .with(
              method: :get,
              path: "/v2/content/#{@content_id}",
              query: "version=1",
            )
            .will_respond_with(
              status: 200,
              body: {
                "content_id" => @content_id,
                "document_type" => Pact.like("special_route"),
                "schema_name" => Pact.like("special_route"),
                "publishing_app" => Pact.like("publisher"),
                "rendering_app" => Pact.like("frontend"),
                "locale" => Pact.like("en"),
                "routes" => Pact.like([{}]),
                "public_updated_at" => Pact.like("2015-07-30T13:58:11.000Z"),
                "details" => Pact.like({}),
                "publication_state" => "superseded"
              },
              headers: {
                "Content-Type" => "application/json; charset=utf-8",
              },
            )
        end

        it "responds with 200 and the superseded content item" do
          response = @api_client.get_content(@content_id, version: 1)
          assert_equal 200, response.code
          assert_equal response["publication_state"], "superseded"
        end
      end

      describe "when requesting the published version" do
        before do
          @content_item = content_item_for_content_id(@content_id)

          publishing_api
            .given("a content item exists in with a superseded version with content_id: #{@content_id}")
            .upon_receiving("a request to return the published content item")
            .with(
              method: :get,
              path: "/v2/content/#{@content_id}",
              query: "version=2",
            )
            .will_respond_with(
              status: 200,
              body: {
                "content_id" => @content_id,
                "document_type" => Pact.like("special_route"),
                "schema_name" => Pact.like("special_route"),
                "publishing_app" => Pact.like("publisher"),
                "rendering_app" => Pact.like("frontend"),
                "locale" => Pact.like("en"),
                "routes" => Pact.like([{}]),
                "public_updated_at" => Pact.like("2015-07-30T13:58:11.000Z"),
                "details" => Pact.like({}),
                "publication_state" => "published"
              },
              headers: {
                "Content-Type" => "application/json; charset=utf-8",
              },
            )
        end

        it "responds with 200 and the published content item" do
          response = @api_client.get_content(@content_id, version: 2)
          assert_equal 200, response.code
          assert_equal response["publication_state"], "published"
        end
      end

      describe "when requesting no specific version" do
        before do
          @content_item = content_item_for_content_id(@content_id)

          publishing_api
            .given("a content item exists in with a superseded version with content_id: #{@content_id}")
            .upon_receiving("a request to return the content item")
            .with(
              method: :get,
              path: "/v2/content/#{@content_id}",
            )
            .will_respond_with(
              status: 200,
              body: {
                "content_id" => @content_id,
                "document_type" => Pact.like("special_route"),
                "schema_name" => Pact.like("special_route"),
                "publishing_app" => Pact.like("publisher"),
                "rendering_app" => Pact.like("frontend"),
                "locale" => Pact.like("en"),
                "routes" => Pact.like([{}]),
                "public_updated_at" => Pact.like("2015-07-30T13:58:11.000Z"),
                "details" => Pact.like({}),
                "publication_state" => "published"
              },
              headers: {
                "Content-Type" => "application/json; charset=utf-8",
              },
            )
        end

        it "responds with 200 and the published content item" do
          response = @api_client.get_content(@content_id)
          assert_equal 200, response.code
          assert_equal response["publication_state"], "published"
        end
      end
    end

    describe "a non-existent item" do
      before do
        publishing_api
          .given("no content exists")
          .upon_receiving("a request for a non-existent content item")
          .with(
            method: :get,
            path: "/v2/content/#{@content_id}",
          )
          .will_respond_with(
            status: 404,
            body: {
              "error" => {
                "code" => 404,
                "message" => Pact.term(generate: "not found", matcher:/\S+/)
              },
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )
      end

      it "responds with 404" do
        assert_nil @api_client.get_content(@content_id)
      end
    end
  end

  describe "#publish" do
    describe "if the publish command succeeds" do
      before do
        publishing_api
          .given("a draft content item exists with content_id: #{@content_id}")
          .upon_receiving("a publish request")
          .with(
            method: :post,
            path: "/v2/content/#{@content_id}/publish",
            body: {
              update_type: "major",
            },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200
          )
      end

      it "responds with 200 if the publish command succeeds" do
        response = @api_client.publish(@content_id, "major")
        assert_equal 200, response.code
      end
    end

    describe "if the content item does not exist" do
      before do
        publishing_api
          .given("no content exists")
          .upon_receiving("a publish request")
          .with(
            method: :post,
            path: "/v2/content/#{@content_id}/publish",
            body: {
              update_type: "major",
            },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 404
          )
      end

      it "responds with 404" do
        error = assert_raises GdsApi::HTTPClientError do
          @api_client.publish(@content_id, "major")
        end

        assert_equal 404, error.code
      end
    end

    describe "if the update information is invalid" do
      before do
        publishing_api
          .given("a draft content item exists with content_id: #{@content_id}")
          .upon_receiving("an invalid publish request")
          .with(
            method: :post,
            path: "/v2/content/#{@content_id}/publish",
            body: {
              "update_type" => ""
            },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 422,
            body: {
              "error" => {
                "code" => 422,
                "message" => Pact.term(generate: "Unprocessable entity", matcher:/\S+/),
                "fields" => {
                  "update_type" => Pact.each_like("is required", :min => 1),
                },
              },
            }
          )
      end

      it "responds with 422" do
        error = assert_raises GdsApi::HTTPClientError do
          @api_client.publish(@content_id, "")
        end

        assert_equal 422, error.code
        assert_equal "Unprocessable entity", error.error_details["error"]["message"]
      end
    end

    describe "if the content item is already published" do
      before do
        publishing_api
          .given("a published content item exists with content_id: #{@content_id}")
          .upon_receiving("a publish request")
          .with(
            method: :post,
            path: "/v2/content/#{@content_id}/publish",
            body: {
              update_type: "major",
            },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 400,
            body: {
              "error" => {
                "code" => 400, "message" => Pact.term(generate: "Cannot publish an already published content item", matcher:/\S+/),
              },
            }
          )
      end

      it "responds with 400" do
        error = assert_raises GdsApi::HTTPClientError do
          @api_client.publish(@content_id, "major")
        end

        assert_equal 400, error.code
        assert_equal "Cannot publish an already published content item", error.error_details["error"]["message"]
      end
    end

    describe "if the update information contains a locale" do
      before do
        publishing_api
          .given("a draft content item exists with content_id: #{@content_id} and locale: fr")
          .upon_receiving("a publish request")
          .with(
            method: :post,
            path: "/v2/content/#{@content_id}/publish",
            body: {
              update_type: "major",
              locale: "fr",
            },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200,
          )
      end

      it "responds with 200 if the publish command succeeds" do
        response = @api_client.publish(@content_id, "major", locale: "fr")
        assert_equal 200, response.code
      end
    end

    describe "optimistic locking" do
      describe "if the content item has not changed since it was requested" do
        before do
          publishing_api
            .given("the content item #{@content_id} is at version 3")
            .upon_receiving("a publish request for version 3")
            .with(
              method: :post,
              path: "/v2/content/#{@content_id}/publish",
              body: {
                update_type: "minor",
                previous_version: 3,
              },
              headers: {
                "Content-Type" => "application/json",
              },
            )
            .will_respond_with(
              status: 200,
            )
        end

        it "responds with 200 OK" do
          response = @api_client.publish(@content_id, "minor", previous_version: 3)
          assert_equal 200, response.code
        end
      end

      describe "if the content item has changed in the meantime" do
        before do
          publishing_api
            .given("the content item #{@content_id} is at version 3")
            .upon_receiving("a publish request for version 2")
            .with(
              method: :post,
              path: "/v2/content/#{@content_id}/publish",
              body: {
                update_type: "minor",
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
                  "message" => Pact.term(generate: "Conflict", matcher:/\S+/),
                  "fields" => {
                    "previous_version" => Pact.each_like("does not match", :min => 1),
                  },
                },
              },
              headers: {
                "Content-Type" => "application/json; charset=utf-8"
              }
            )
        end

        it "responds with 409 Conflict" do
          error = assert_raises GdsApi::HTTPClientError do
            @api_client.publish(@content_id, "minor", previous_version: 2)
          end
          assert_equal 409, error.code
          assert_equal "Conflict", error.error_details["error"]["message"]
        end
      end
    end
  end

  describe "#unpublish" do
    describe "if the unpublish command succeeds" do
      before do
        publishing_api
          .given("a published content item exists with content_id: #{@content_id}")
          .upon_receiving("an unpublish request")
          .with(
            method: :post,
            path: "/v2/content/#{@content_id}/unpublish",
            body: {
              type: "gone",
            },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200
          )
      end

      it "responds with 200" do
        response = @api_client.unpublish(@content_id, type: "gone")
        assert_equal 200, response.code
      end
    end

    describe "if the content item does not exist" do
      before do
        publishing_api
          .given("no content exists")
          .upon_receiving("an unpublish request")
          .with(
            method: :post,
            path: "/v2/content/#{@content_id}/unpublish",
            body: {
              type: "gone",
            },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 404
          )
      end

      it "responds with 404" do
        error = assert_raises GdsApi::HTTPClientError do
          @api_client.unpublish(@content_id, type: "gone")
        end

        assert_equal 404, error.code
      end
    end

    describe "if the type is incorrect" do
      before do
        publishing_api
          .given("a published content item exists with content_id: #{@content_id}")
          .upon_receiving("an invalid unpublish request")
          .with(
            method: :post,
            path: "/v2/content/#{@content_id}/unpublish",
            body: {
              type: "not-a-valid-type",
            },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 422,
            body: {
              "error" => {
                "code" => 422,
                "message" => Pact.term(generate: "not-a-valid-type is not a valid unpublishing type", matcher:/\S+/),
                "fields" => {},
              },
            }
          )
      end

      it "responds with 422" do
        error = assert_raises GdsApi::HTTPClientError do
          @api_client.unpublish(@content_id, type: "not-a-valid-type")
        end

        assert_equal 422, error.code
        assert_equal "not-a-valid-type is not a valid unpublishing type", error.error_details["error"]["message"]
      end
    end

    describe "if the content item is already unpublished" do
      before do
        publishing_api
          .given("an unpublished content item exists with content_id: #{@content_id}")
          .upon_receiving("an unpublish request")
          .with(
            method: :post,
            path: "/v2/content/#{@content_id}/unpublish",
            body: {
              type: "gone",
            },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200
          )
      end

      it "responds with 200 and updates the unpublishing" do
        response = @api_client.unpublish(@content_id, type: "gone")
        assert_equal 200, response.code
      end
    end

    describe "optimistic locking" do
      describe "if the content item has not changed since it was requested" do
        before do
          publishing_api
            .given("the published content item #{@content_id} is at version 3")
            .upon_receiving("an unpublish request for version 3")
            .with(
              method: :post,
              path: "/v2/content/#{@content_id}/unpublish",
              body: {
                type: "gone",
                previous_version: 3,
              },
              headers: {
                "Content-Type" => "application/json",
              },
            )
            .will_respond_with(
              status: 200,
            )
        end

        it "responds with 200 OK" do
          response = @api_client.unpublish(@content_id, type: "gone", previous_version: 3)
          assert_equal 200, response.code
        end
      end

      describe "if the content item has changed in the meantime" do
        before do
          publishing_api
            .given("the published content item #{@content_id} is at version 3")
            .upon_receiving("an unpublish request for version 2")
            .with(
              method: :post,
              path: "/v2/content/#{@content_id}/unpublish",
              body: {
                type: "gone",
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
                  "message" => Pact.term(generate: "Conflict", matcher:/\S+/),
                  "fields" => {
                    "previous_version" => Pact.each_like("does not match", :min => 1),
                  },
                },
              },
              headers: {
                "Content-Type" => "application/json; charset=utf-8"
              }
            )
        end

        it "responds with 409 Conflict" do
          error = assert_raises GdsApi::HTTPClientError do
            @api_client.unpublish(@content_id, type: "gone", previous_version: 2)
          end
          assert_equal 409, error.code
          assert_equal "Conflict", error.error_details["error"]["message"]
        end
      end
    end
  end

  describe "#patch_links" do
    describe "when setting links of the same type" do
      before do
        publishing_api
          .given("organisation links exist for content_id #{@content_id}")
          .upon_receiving("a patch organisation links request")
          .with(
            method: :patch,
            path: "/v2/links/#{@content_id}",
            body: {
              links: {
                organisations: ["591436ab-c2ae-416f-a3c5-1901d633fbfb"],
              }
            },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200,
            body: {
              links: {
                organisations: ["591436ab-c2ae-416f-a3c5-1901d633fbfb"],
              }
            }
          )
      end

      it "replaces the links and responds with the new links" do
        response = @api_client.patch_links(@content_id, links: {
          organisations: ["591436ab-c2ae-416f-a3c5-1901d633fbfb"],
        })
        assert_equal 200, response.code
        assert_equal ["591436ab-c2ae-416f-a3c5-1901d633fbfb"], response.links.organisations
      end
    end

    describe "when setting links of a different type" do
      before do
        publishing_api
          .given("organisation links exist for content_id #{@content_id}")
          .upon_receiving("a patch topic links request")
          .with(
            method: :patch,
            path: "/v2/links/#{@content_id}",
            body: {
              links: {
                topics: ["225df4a8-2945-4e9b-8799-df7424a90b69"],
              }
            },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200,
            body: {
              links: {
                topics: ["225df4a8-2945-4e9b-8799-df7424a90b69"],
                organisations: ["20583132-1619-4c68-af24-77583172c070"]
              }
            }
          )
      end

      it "adds the new type of links and responds with the whole link set" do
        response = @api_client.patch_links(@content_id, links: {
          topics: ["225df4a8-2945-4e9b-8799-df7424a90b69"],
        })

        assert_equal 200, response.code
        assert_equal(OpenStruct.new(
          topics: ["225df4a8-2945-4e9b-8799-df7424a90b69"],
          organisations: ["20583132-1619-4c68-af24-77583172c070"],
        ), response.links)
      end
    end

    describe "when deleting links of a specific type" do
      before do
        publishing_api
          .given("organisation links exist for content_id #{@content_id}")
          .upon_receiving("a patch blank organisation links request")
          .with(
            method: :patch,
            path: "/v2/links/#{@content_id}",
            body: {
              links: {
                organisations: [],
              }
            },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200,
            body: {
              links: {}
            }
          )
      end

      it "responds with the links" do
        response = @api_client.patch_links(@content_id, links: {
          organisations: [],
        })

        assert_equal 200, response.code
        assert_equal OpenStruct.new({}), response.links
      end
    end

    describe "when there's no links entry" do
      before do
        publishing_api
          .given("no links exist for content_id #{@content_id}")
          .upon_receiving("a patch organisation links request")
          .with(
            method: :patch,
            path: "/v2/links/#{@content_id}",
            body: {
              links: {
                organisations: ["591436ab-c2ae-416f-a3c5-1901d633fbfb"],
              }
            },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200,
            body: {
              links: {
                organisations: ["591436ab-c2ae-416f-a3c5-1901d633fbfb"],
              }
            },
          )
      end

      it "responds with the links" do
        response = @api_client.patch_links(@content_id, links: {
          organisations: ["591436ab-c2ae-416f-a3c5-1901d633fbfb"],
        })

        assert_equal 200, response.code
        assert_equal(OpenStruct.new(
          organisations: ["591436ab-c2ae-416f-a3c5-1901d633fbfb"],
        ), response.links)
      end
    end

    describe "optimistic locking" do
      describe "if the linkset has not changed since it was requested" do
        before do
          publishing_api
            .given("the linkset for #{@content_id} is at version 3")
            .upon_receiving("a request to update the linkset at version 3")
            .with(
              method: :patch,
              path: "/v2/links/#{@content_id}",
              body: {
                links: {
                  organisations: ["591436ab-c2ae-416f-a3c5-1901d633fbfb"],
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
        end

        it "responds with 200 OK" do
          response = @api_client.patch_links(@content_id,
            links: {
              organisations: ["591436ab-c2ae-416f-a3c5-1901d633fbfb"],
            },
            previous_version: 3,
          )

          assert_equal 200, response.code
        end
      end

      describe "if the content item has changed in the meantime" do
        before do
          publishing_api
            .given("the linkset for #{@content_id} is at version 3")
            .upon_receiving("a request to update the linkset at version 2")
            .with(
              method: :patch,
              path: "/v2/links/#{@content_id}",
              body: {
                links: {
                  organisations: ["591436ab-c2ae-416f-a3c5-1901d633fbfb"],
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
                  "message" => Pact.term(generate: "Conflict", matcher:/\S+/),
                  "fields" => {
                    "previous_version" => Pact.each_like("does not match", :min => 1),
                  },
                },
              },
              headers: {
                "Content-Type" => "application/json; charset=utf-8"
              }
            )
        end

        it "responds with 409 Conflict" do
          error = assert_raises GdsApi::HTTPClientError do
            @api_client.patch_links(@content_id,
              links: {
                organisations: ["591436ab-c2ae-416f-a3c5-1901d633fbfb"],
              },
              previous_version: 2,
            )
          end

          assert_equal 409, error.code
          assert_equal "Conflict", error.error_details["error"]["message"]
        end
      end
    end
  end

  describe "#get_linkables" do
    let(:linkables) {
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
    }

    it "returns the content items of a given document_type" do
      publishing_api
        .given("there is content with format 'topic'")
        .upon_receiving("a get linkables request")
        .with(
          method: :get,
          path: "/v2/linkables",
          query: "document_type=topic",
          headers: {
            "Content-Type" => "application/json",
          },
        )
        .will_respond_with(
          status: 200,
          body: linkables,
        )

      response = @api_client.get_linkables(document_type: "topic")
      assert_equal 200, response.code
      assert_equal linkables, response.to_a

      # `format` is supported but deprecated for backwards compatibility
      response = @api_client.get_linkables(format: "topic")
      assert_equal 200, response.code
      assert_equal linkables, response.to_a
    end
  end

  describe "#get_content_items" do
    it "returns the content items of a certain format" do
      publishing_api
        .given("there is content with format 'topic'")
        .upon_receiving("a get entries request")
        .with(
          method: :get,
          path: "/v2/content",
          query: "content_format=topic&fields%5B%5D=title&fields%5B%5D=base_path",
          headers: {
            "Content-Type" => "application/json",
          },
        )
        .will_respond_with(
          status: 200,
          body: {
            total: 2,
            pages: 1,
            current_page: 1,
            links: [{
              href: "http://example.org/v2/content?content_format=topic&fields[]=title&fields[]=base_path&page=1",
              rel: "self"
            }],
            results: [
              { title: 'Content Item A', base_path: '/a-base-path' },
              { title: 'Content Item B', base_path: '/another-base-path' },
            ]
          }
        )

      response = @api_client.get_content_items(
        content_format: 'topic',
        fields: [:title, :base_path],
      )

      assert_equal 200, response.code

      assert_equal [
        ["total", 2],
        ["pages", 1],
        ["current_page", 1],
        ["links", [{"href"=>"http://example.org/v2/content?content_format=topic&fields[]=title&fields[]=base_path&page=1", "rel"=>"self"}]],
        ["results", [{"title"=>"Content Item A", "base_path"=>"/a-base-path"}, {"title"=>"Content Item B", "base_path"=>"/another-base-path"}]]
      ], response.to_a

    end

    it "returns the content items in english locale by default" do
      publishing_api
        .given("a content item exists in multiple locales with content_id: #{@content_id}")
        .upon_receiving("a get entries request")
        .with(
          method: :get,
          path: "/v2/content",
          query: "content_format=topic&fields%5B%5D=content_id&fields%5B%5D=locale",
          headers: {
            "Content-Type" => "application/json",
          },
        )
        .will_respond_with(
          status: 200,
          body: {
            total: 1,
            pages: 1,
            current_page: 1,
            links: [{
              href: "http://example.org/v2/content?content_format=topic&fields[]=content_id&fields[]=locale&page=1",
              rel: "self"
            }],
            results: [
              { content_id: @content_id, locale: "en" }
            ]
          }
        )

      response = @api_client.get_content_items(
        content_format: 'topic',
        fields: [:content_id, :locale],
      )

      assert_equal 200, response.code

      assert_equal [
        ["total", 1],
        ["pages", 1],
        ["current_page", 1],
        ["links", [{"href"=>"http://example.org/v2/content?content_format=topic&fields[]=content_id&fields[]=locale&page=1", "rel"=>"self"}]],
        ["results", [{"content_id"=>"bed722e6-db68-43e5-9079-063f623335a7", "locale"=>"en"}]]
      ], response.to_a
    end

    it "returns the content items in a specific locale" do
      publishing_api
        .given("a content item exists in multiple locales with content_id: #{@content_id}")
        .upon_receiving("a get entries request with a specific locale")
        .with(
          method: :get,
          path: "/v2/content",
          query: "content_format=topic&fields%5B%5D=content_id&fields%5B%5D=locale&locale=fr",
          headers: {
            "Content-Type" => "application/json",
          },
        )
        .will_respond_with(
          status: 200,
          body: {
            total: 1,
            pages: 1,
            current_page: 1,
            links: [{
              href: "http://example.org/v2/content?content_format=topic&fields[]=content_id&fields[]=locale&locale=fr&page=1",
              rel: "self"
            }],
            results: [
              { content_id: @content_id, locale: "fr" }
            ]
          }
        )

      response = @api_client.get_content_items(
        content_format: 'topic',
        fields: [:content_id, :locale],
        locale: 'fr',
      )

      assert_equal 200, response.code
      assert_equal [
        ["total", 1],
        ["pages", 1],
        ["current_page", 1],
        ["links", [{"href"=>"http://example.org/v2/content?content_format=topic&fields[]=content_id&fields[]=locale&locale=fr&page=1", "rel"=>"self"}]],
        ["results", [{"content_id"=>"bed722e6-db68-43e5-9079-063f623335a7", "locale"=>"fr"}]]
      ], response.to_a
    end

    it "returns the content items in all the available locales" do
      publishing_api
        .given("a content item exists in multiple locales with content_id: #{@content_id}")
        .upon_receiving("a get entries request with an 'all' locale")
        .with(
          method: :get,
          path: "/v2/content",
          query: "content_format=topic&fields%5B%5D=content_id&fields%5B%5D=locale&locale=all",
          headers: {
            "Content-Type" => "application/json",
          },
        )
        .will_respond_with(
          status: 200,
          body: {
            total: 3,
            pages: 1,
            current_page: 1,
            links: [{
              href: "http://example.org/v2/content?content_format=topic&fields[]=content_id&fields[]=locale&locale=all&page=1",
              rel: "self"
            }],
            results: [
              { content_id: @content_id, locale: "en" },
              { content_id: @content_id, locale: "fr" },
              { content_id: @content_id, locale: "ar" },
            ]
          }
        )

      response = @api_client.get_content_items(
        content_format: 'topic',
        fields: [:content_id, :locale],
        locale: 'all',
      )

      assert_equal 200, response.code
      assert_equal [
        ["total", 3],
        ["pages", 1], ["current_page", 1],
        ["links",
         [{"href"=>"http://example.org/v2/content?content_format=topic&fields[]=content_id&fields[]=locale&locale=all&page=1", "rel"=>"self"}]],
        ["results",
         [{"content_id"=>"bed722e6-db68-43e5-9079-063f623335a7", "locale"=>"en"},
          {"content_id"=>"bed722e6-db68-43e5-9079-063f623335a7", "locale"=>"fr"},
          {"content_id"=>"bed722e6-db68-43e5-9079-063f623335a7", "locale"=>"ar"}]]
      ], response.to_a
    end

    it "returns details hashes" do
      publishing_api
        .given("a content item exists with content_id: #{@content_id} and it has details")
        .upon_receiving("a get entries request with details field")
        .with(
          method: :get,
          path: "/v2/content",
          query: "content_format=topic&fields%5B%5D=content_id&fields%5B%5D=details",
          headers: {
            "Content-Type" => "application/json",
          },
        )
        .will_respond_with(
          status: 200,
          body: {
            total: 1,
            pages: 1,
            current_page: 1,
            links: [{
              href: "http://example.org/v2/content?content_format=topic&fields[]=content_id&fields[]=details&page=1",
              rel: "self"
            }],
            results: [
              { content_id: @content_id, details: {foo: :bar} }
            ]
          }
        )

      response = @api_client.get_content_items(
        content_format: 'topic',
        fields: [:content_id, :details],
      )

      assert_equal 200, response.code

      assert_equal [
        ["total", 1],
        ["pages", 1],
        ["current_page", 1],
        ["links", [{"href"=>"http://example.org/v2/content?content_format=topic&fields[]=content_id&fields[]=details&page=1", "rel"=>"self"}]],
        ["results", [{"content_id"=>"bed722e6-db68-43e5-9079-063f623335a7", "details"=>{"foo"=>"bar"}}]]
      ], response.to_a
    end
  end

  describe "#discard_draft(content_id, options = {})" do
    describe "when the content item exists" do
      before do
        publishing_api
          .given("a content item exists with content_id: #{@content_id}")
          .upon_receiving("a request to discard draft content")
          .with(
            method: :post,
            path: "/v2/content/#{@content_id}/discard-draft",
            body: {},
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200,
          )
      end

      it "responds with 200" do
        response = @api_client.discard_draft(@content_id)
        assert_equal 200, response.code
      end
    end

    describe "when the content item exists and is French" do
      before do
        publishing_api
          .given("a French content item exists with content_id: #{@content_id}")
          .upon_receiving("a request to discard French draft content")
          .with(
            method: :post,
            path: "/v2/content/#{@content_id}/discard-draft",
            body: {
              locale: "fr",
            },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200,
          )
      end

      it "responds with 200" do
        response = @api_client.discard_draft(@content_id, locale: "fr")
        assert_equal 200, response.code
      end
    end

    describe "when there is no content with that content_id" do
      before do
        publishing_api
          .given("no content exists")
          .upon_receiving("a request to discard draft content")
          .with(
            method: :post,
            path: "/v2/content/#{@content_id}/discard-draft",
            body: {},
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 404,
          )
      end

      it "responds with a 404" do
        error = assert_raises GdsApi::HTTPClientError do
          @api_client.discard_draft(@content_id)
        end

        assert_equal 404, error.code
      end
    end
  end
  describe "#get_linked_items" do
    describe "if the content item does not exist" do
      before do
        publishing_api
          .given("no content exists")
          .upon_receiving("a request to return the items linked to it")
          .with(
            method: :get,
            path: "/v2/linked/#{@content_id}",
            query: "fields%5B%5D=content_id&fields%5B%5D=base_path&link_type=topic",
          )
          .will_respond_with(
            status: 404,
            body: {
              "error" => {
                "code" => 404,
                "message" => Pact.term(generate: "not found", matcher:/\S+/)
              },
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )
      end

      it "404s" do
        response = @api_client.get_linked_items(
          @content_id,
          {
            link_type: "topic",
            fields: ["content_id", "base_path"],
          }
        )
        assert_nil response
      end
    end

    describe "there are two documents that link to the wanted document" do
      before do
        content_id2 = "08dfd5c3-d935-4e81-88fd-cfe65b78893d"
        content_id3 = "e2961462-bc37-48e9-bb98-c981ef1a2d59"

        @linked_content_item = content_item_for_content_id("6cb2cf8c-670f-4de3-97d5-6ad9114581c7")
        @linking_content_item1 = content_item_for_content_id(content_id3,
          "base_path" => "/item-b",
          "links" => {
            "topic" => [ @linked_content_item['content_id1'] ]
        })
        @linking_content_item2 = content_item_for_content_id(content_id2,
          "base_path" => "/item-a",
          "links" => {
            "topic" => [ @linked_content_item['content_id1'] ],
        })

        publishing_api
          .given("there are two documents with a 'topic' link to another document")
          .upon_receiving("a get linked request")
          .with(
            method: :get,
            path: "/v2/linked/" + @linked_content_item['content_id'],
            query: "fields%5B%5D=content_id&fields%5B%5D=base_path&link_type=topic",
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 200,
            body: [
              {
                content_id: @linking_content_item1["content_id"],
                base_path: @linking_content_item1["base_path"]
              },
              {
                content_id: @linking_content_item2["content_id"],
                base_path: @linking_content_item2["base_path"]
              }
            ]
          )
      end

      it "returns the requested fields of linking items" do
        response = @api_client.get_linked_items(
          @linked_content_item["content_id"],
          {
            link_type: "topic",
            fields: ["content_id", "base_path"],
          }
        )
        assert_equal 200, response.code

        expected_documents = [
          { "content_id" => @linking_content_item2["content_id"], "base_path" => "/item-a" },
          { "content_id" => @linking_content_item1["content_id"], "base_path" => "/item-b" },
        ]

        expected_documents.each do |document|
          response.to_a.must_include document
        end
      end
    end
  end

  describe "content ID validation" do
    [:get_content, :get_links, :get_linked_items, :discard_draft].each do |method|
      it "happens on #{method}" do
        proc { @api_client.send(method, nil) }.must_raise ArgumentError
      end
    end

    it "happens on publish" do
      proc { @api_client.publish(nil, "major") }.must_raise ArgumentError
    end

    it "happens on put_content" do
      proc { @api_client.put_content(nil, {}) }.must_raise ArgumentError
    end

    it "happens on patch_links" do
      proc { @api_client.patch_links(nil, links: {}) }.must_raise ArgumentError
    end
  end
end
