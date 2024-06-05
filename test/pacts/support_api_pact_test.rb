require "test_helper"
require "gds_api/support_api"

describe "GdsApi::SupportApi pact tests" do
  include PactTest

  describe "#raise_support_ticket" do
    let(:api_client) { GdsApi::SupportApi.new(support_api_host) }

    it "responds with a 201 Success if the parameters provided are valid" do
      support_api
        .given("the parameters are valid")
        .upon_receiving("a raise ticket request")
        .with(
          method: :post,
          path: "/support-tickets",
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
          body: {
            subject: "Feedback for app",
            tags: %w[app_name],
            user_agent: "Safari",
            description: "There is something wrong with this page.",
          },
        )
        .will_respond_with(
          status: 201,
          body: {
            status: "success",
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.raise_support_ticket(
        subject: "Feedback for app",
        tags: %w[app_name],
        user_agent: "Safari",
        description: "There is something wrong with this page.",
      )
    end

    it "responds with 422 Error when required parameters are not provided" do
      support_api
      .given("the required parameters are not provided")
      .upon_receiving("a raise ticket request")
      .with(
        method: :post,
        path: "/support-tickets",
        headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        body: {
          subject: "Ticket without body",
        },
      )
      .will_respond_with(
        status: 422,
        body: {
          status: "error",
        },
      )

      assert_raises GdsApi::HTTPUnprocessableEntity do
        api_client.raise_support_ticket(subject: "Ticket without body")
      end
    end
  end
end
