require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#put_path pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }

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
        error_code: Pact.like("base_path_already_in_use"),
        body: {
          "error" => {
            "code" => 422,
            "message" => Pact.term(generate: "Unprocessable", matcher: /\S+/),
            "fields" => {
              "base_path" => Pact.each_like(
                {
                  "error" => Pact.term(generate: "/test-item is already reserved by publisher", matcher: /\S+/),
                  "code" => Pact.like("base_path_already_in_use"),
                },
                min: 1,
              ),
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
