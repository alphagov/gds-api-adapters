require "test_helper"
require "gds_api/support_api"

describe "GdsApi::SignonApi pact tests" do
  include PactTest

  describe "#get_users" do
    let(:bearer_token) { "SOME_BEARER_TOKEN" }
    let(:api_client) { GdsApi::SignonApi.new(signon_api_host, { bearer_token: }) }

    it "returns a list of users" do
      uuids = %w[9ef9779f-3cba-481a-9a73-00d39e33eb7b b55873b4-bc83-4efe-bdc9-6b7d381a723e 64c7d994-17e0-44d9-97b0-87b43a581eb9]
      signon_api
        .given("users exist with the UUIDs #{uuids[0]}, #{uuids[1]} and #{uuids[2]}")
        .upon_receiving("a raise ticket request")
        .with(
          method: :get,
          path: "/api/users",
          headers: GdsApi::JsonClient.default_request_headers.merge("Authorization" => "Bearer #{bearer_token}"),
          query: "uuids%5B%5D=#{uuids[0]}&uuids%5B%5D=#{uuids[1]}&uuids%5B%5D=#{uuids[2]}",
        )
        .will_respond_with(
          status: 200,
          body: [
            {
              "uid": "9ef9779f-3cba-481a-9a73-00d39e33eb7b",
              "name": Pact.like("Some user"),
              "email": Pact.like("user@example.com"),
              "organisation": nil,
            },
            {
              "uid": "b55873b4-bc83-4efe-bdc9-6b7d381a723e",
              "name": Pact.like("Some user"),
              "email": Pact.like("user@example.com"),
              "organisation": nil,
            },
            {
              "uid": "64c7d994-17e0-44d9-97b0-87b43a581eb9",
              "name": Pact.like("Some user"),
              "email": Pact.like("user@example.com"),
              "organisation": nil,
            },
          ],
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.get_users(uuids:)
    end
  end
end
