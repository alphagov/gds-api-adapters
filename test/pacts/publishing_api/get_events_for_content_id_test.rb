require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#get_expanded_links pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }

  let(:content_id) { "b317151d-0b05-4641-8494-596b6f880b20" }

  let(:publish_event) do
    {
      "id" => Pact.like(1592),
      "action" => "Publish",
      "user_uid" => Pact.like("6dbbcb5d-108c-4582-a8cb-393a57442810"),
      "created_at" => "2023-01-12T00:00:00.000Z",
      "updated_at" => "2023-01-12T00:00:00.000Z",
      "request_id" => Pact.like("5314-1734346886.624-127.0.0.1-7562"),
      "content_id" => "b317151d-0b05-4641-8494-596b6f880b20",
      "payload" => {
        "title" => "An exciting piece of content",
        "locale" => "en",
        "content_id" => "b317151d-0b05-4641-8494-596b6f880b20",
      },
    }
  end

  let(:put_event) do
    {
      "id" => Pact.like(1591),
      "action" => "PutContent",
      "user_uid" => Pact.like("7d548b99-3490-482e-b150-9d71eb89a0ca"),
      "created_at" => "2023-01-01T00:00:00.000Z",
      "updated_at" => "2023-01-01T00:00:00.000Z",
      "request_id" => Pact.like("7583-1734346880.778-127.0.0.1-7572"),
      "content_id" => "b317151d-0b05-4641-8494-596b6f880b20",
      "payload" => {
        "title" => "An exciting piece of content",
        "locale" => "en",
        "content_id" => "b317151d-0b05-4641-8494-596b6f880b20",
      },
    }
  end

  let(:host_content_update_event) do
    {
      "id" => Pact.like(1593),
      "action" => "HostContentUpdateJob",
      "user_uid" => Pact.like("1e6972b4-d4da-4589-976e-f6e5ca92a752"),
      "created_at" => "2024-01-01T00:00:00.000Z",
      "updated_at" => "2024-01-01T00:00:00.000Z",
      "request_id" => Pact.like("3830-1734347673.256-127.0.0.1-2487"),
      "content_id" => "b317151d-0b05-4641-8494-596b6f880b20",
      "payload" => {
        "title" => "An exciting piece of content",
        "locale" => "en",
        "content_id" => "b317151d-0b05-4641-8494-596b6f880b20",
      },
    }
  end

  it "responds with a list of events for a content ID" do
    expected_body = [put_event, publish_event, host_content_update_event]

    publishing_api
      .given("a selection of events exists for content ID #{content_id}")
      .upon_receiving("a get_events_for_content_id request without params")
      .with(
        method: :get,
        path: "/v2/content/#{content_id}/events",
      )
      .will_respond_with(
        status: 200,
        body: expected_body,
      )

    api_client.get_events_for_content_id(content_id)
  end

  it "allows filtering by action" do
    expected_body = [put_event]

    publishing_api
      .given("a selection of events exists for content ID #{content_id}")
      .upon_receiving("a get_events_for_content_id request with an action param")
      .with(
        method: :get,
        path: "/v2/content/#{content_id}/events",
        query: "action=PutContent",
      )
      .will_respond_with(
        status: 200,
        body: expected_body,
      )

    api_client.get_events_for_content_id(content_id, { action: "PutContent" })
  end

  it "allows filtering by from date" do
    expected_body = [publish_event, host_content_update_event]

    publishing_api
      .given("a selection of events exists for content ID #{content_id}")
      .upon_receiving("a get_events_for_content_id request with a from param")
      .with(
        method: :get,
        path: "/v2/content/#{content_id}/events",
        query: "from=2023-01-11T00:00:00.000Z",
      )
      .will_respond_with(
        status: 200,
        body: expected_body,
      )

    api_client.get_events_for_content_id(content_id, { from: "2023-01-11T00:00:00.000Z" })
  end

  it "allows filtering by to date" do
    expected_body = [put_event]

    publishing_api
      .given("a selection of events exists for content ID #{content_id}")
      .upon_receiving("a get_events_for_content_id request with a to param")
      .with(
        method: :get,
        path: "/v2/content/#{content_id}/events",
        query: "to=2023-01-11T00:00:00.000Z",
      )
      .will_respond_with(
        status: 200,
        body: expected_body,
      )

    api_client.get_events_for_content_id(content_id, { to: "2023-01-11T00:00:00.000Z" })
  end

  it "allows filtering by from and to date" do
    expected_body = [put_event, publish_event]

    publishing_api
      .given("a selection of events exists for content ID #{content_id}")
      .upon_receiving("a get_events_for_content_id request with a from and to param")
      .with(
        method: :get,
        path: "/v2/content/#{content_id}/events",
        query: "from=2022-12-31T00:00:00.000Z&to=2023-01-13T00:00:00.000Z",
      )
      .will_respond_with(
        status: 200,
        body: expected_body,
      )

    api_client.get_events_for_content_id(content_id, { from: "2022-12-31T00:00:00.000Z", to: "2023-01-13T00:00:00.000Z" })
  end

  it "allows filtering by from and to date and action" do
    expected_body = [put_event]

    publishing_api
      .given("a selection of events exists for content ID #{content_id}")
      .upon_receiving("a get_events_for_content_id request with action, from and to params")
      .with(
        method: :get,
        path: "/v2/content/#{content_id}/events",
        query: "action=PutContent&from=2022-12-31T00:00:00.000Z&to=2023-01-13T00:00:00.000Z",
      )
      .will_respond_with(
        status: 200,
        body: expected_body,
      )

    api_client.get_events_for_content_id(content_id, { action: "PutContent", from: "2022-12-31T00:00:00.000Z", to: "2023-01-13T00:00:00.000Z" })
  end
end
