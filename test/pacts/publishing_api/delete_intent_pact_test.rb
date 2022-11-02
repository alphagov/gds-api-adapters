require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#delete_intent pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }

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
