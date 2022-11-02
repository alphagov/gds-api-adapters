require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#get_link_changes pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }
  let(:link_changes) do
    { "link_changes" => [
      {
        "source" => { "title" => "Edition Title A1",
                      "base_path" => "/base/path/a1",
                      "content_id" => "aaaaaaaa-aaaa-1aaa-aaaa-aaaaaaaaaaaa" },
        "target" => { "title" => "Edition Title B1",
                      "base_path" => "/base/path/b1",
                      "content_id" => "bbbbbbbb-bbbb-1bbb-bbbb-bbbbbbbbbbbb" },
        "link_type" => "taxons",
        "change" => "add",
        "user_uid" => "11111111-1111-1111-1111-111111111111",
        "created_at" => "2017-01-01T09:00:00.100Z",
      },
      {
        "source" => { "title" => "Edition Title A2",
                      "base_path" => "/base/path/a2",
                      "content_id" => "aaaaaaaa-aaaa-2aaa-aaaa-aaaaaaaaaaaa" },
        "target" => { "title" => "Edition Title B2",
                      "base_path" => "/base/path/b2",
                      "content_id" => "bbbbbbbb-bbbb-2bbb-bbbb-bbbbbbbbbbbb" },
        "link_type" => "taxons",
        "change" => "remove",
        "user_uid" => "22222222-2222-2222-2222-222222222222",
        "created_at" => "2017-01-01T09:00:00.100Z",
      },
    ] }
  end

  it "returns the changes for a single link_type" do
    publishing_api
      .given("there are two link changes with a link_type of 'taxons'")
      .upon_receiving("a get links changes request for changes with a link_type of 'taxons'")
      .with(
        method: :get,
        path: "/v2/links/changes",
        query: "link_types%5B%5D=taxons",
      )
      .will_respond_with(
        status: 200,
        body: link_changes,
      )

    api_client.get_links_changes(link_types: %w[taxons])
  end
end
