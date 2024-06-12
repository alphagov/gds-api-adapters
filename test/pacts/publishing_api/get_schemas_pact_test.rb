require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi##get_schemas_by_name pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }

  let(:schemas) do
    {
      "email_address": { "some": "schema" },
      "tax_licence": { "another": "schema" },
    }
  end

  before do
    publishing_api
      .given("there are two schemas")
      .upon_receiving("a get schemas request")
      .with(
        method: :get,
        path: "/v2/schemas",
      )
      .will_respond_with(
        status: 200,
        body: :schemas,
      )
  end

  it "returns all the schemas" do
    response = api_client.get_schemas
    assert_equal 200, response.code
    assert_equal :schemas, response.body
  end
end
