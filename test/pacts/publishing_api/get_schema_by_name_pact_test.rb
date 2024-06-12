require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi##get_schemas_by_name pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }

  let(:schema) do
    {
      "/govuk/publishing-api/content_schemas/dist/formats/email_address/publisher_v2/schema.json": {
        type: "object",
        required: %w[a],
        properties: {
          email_address: { "some" => "schema" },
        },
      },
    }
  end

  describe "when a schema is found" do
    before do
      publishing_api
        .given("there is a schema for an email_address")
        .upon_receiving("a get schema by name request")
        .with(
          method: :get,
          path: "/v2/schemas/email_address",
        )
        .will_respond_with(
          status: 200,
          body: schema,
        )
    end

    it "returns the named schema" do
      response = api_client.get_schema("email_address")
      assert_equal(schema.to_json, response.to_json)
    end
  end

  describe "when a schema is not found" do
    before do
      publishing_api
        .given("there is not a schema for an email_address")
        .upon_receiving("a get schema by name request")
        .with(
          method: :get,
          path: "/v2/schemas/email_address",
        )
        .will_respond_with(
          status: 404,
        )
    end

    it "returns a 404 error" do
      assert_raises(GdsApi::HTTPNotFound) do
        api_client.get_schema("email_address")
      end
    end
  end
end
