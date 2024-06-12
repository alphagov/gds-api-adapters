require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#get_schemas pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }

  let(:schemas) do
    {
      "email_address": {
        type: "object",
        required: %w[a],
        properties: {
          email_address: { "some" => "schema" },
        },
      },
      "tax_license": {
        type: "object",
        required: %w[a],
        properties: {
          tax_license: { "another" => "schema" },
        },
      },
    }
  end

  before do
    publishing_api
      .given("there are publisher schemas")
      .upon_receiving("a get schemas request")
      .with(
        method: :get,
        path: "/v2/schemas",
      )
      .will_respond_with(
        status: 200,
        body: schemas,
      )
  end

  it "returns all the schemas" do
    response = api_client.get_schemas
    assert_equal(schemas.to_json, response.to_json)
  end
end
