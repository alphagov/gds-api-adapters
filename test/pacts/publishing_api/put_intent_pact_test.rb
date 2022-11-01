require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#put_intent pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }

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
