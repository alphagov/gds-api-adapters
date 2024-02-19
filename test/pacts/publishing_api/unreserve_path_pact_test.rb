require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#unreserve_path pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }

  it "responds with 200 OK if reservation is owned by the app" do
    publishing_app = "publisher"
    base_path = "/test-item"

    publishing_api
      .given("/test-item has been reserved by the Publisher application")
      .upon_receiving("a request to unreserve a path")
      .with(
        method: :delete,
        path: "/paths#{base_path}",
        body: { publishing_app: },
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
        body: { publishing_app: },
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
