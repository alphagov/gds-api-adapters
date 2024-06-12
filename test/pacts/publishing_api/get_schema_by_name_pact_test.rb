require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#get_schemas pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }

  let(:schema) do
    {
      "email_address": { "some": "schema" },
    }
  end

  describe "when a schema is found" do
    before do
      publishing_api
        .given("there is a schema with given name")
        .upon_receiving("a get schema by name request")
        .with(
          method: :get,
          path: "/v2/schemas/email_address",
        )
        .will_respond_with(
          status: 200,
          body: :schema,
        )
    end

    it "returns the named schema" do
      response = api_client.get_schemas
      assert_equal 200, response.code
      assert_equal :schema, response.body
    end
  end

  describe "when a schema is not found" do
    before do
      publishing_api
        .given("there is not a schema for a given name")
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
      response = api_client.get_schema("email_address")
      assert_equal 404, response.code
    end
  end
end
