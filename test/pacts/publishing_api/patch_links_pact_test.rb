require "test_helper"
require "gds_api/publishing_api"

describe "GdsApi::PublishingApi#patch_links pact tests" do
  include PactTest

  let(:api_client) { GdsApi::PublishingApi.new(publishing_api_host) }
  let(:content_id) { "bed722e6-db68-43e5-9079-063f623335a7" }

  it "replaces the links and responds with the new links when setting links of the same type" do
    publishing_api
      .given("organisation links exist for content_id #{content_id}")
      .upon_receiving("a patch organisation links request")
      .with(
        method: :patch,
        path: "/v2/links/#{content_id}",
        body: {
          links: {
            organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
          },
        },
        headers: {
          "Content-Type" => "application/json",
        },
      )
      .will_respond_with(
        status: 200,
        body: {
          links: {
            organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
          },
        },
      )

    api_client.patch_links(
      content_id,
      links: {
        organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
      },
    )
  end

  it "adds the new type of links and responds with the whole link set when setting links of a different type" do
    publishing_api
      .given("organisation links exist for content_id #{content_id}")
      .upon_receiving("a patch taxons links request")
      .with(
        method: :patch,
        path: "/v2/links/#{content_id}",
        body: {
          links: {
            taxons: %w[225df4a8-2945-4e9b-8799-df7424a90b69],
          },
        },
        headers: {
          "Content-Type" => "application/json",
        },
      )
      .will_respond_with(
        status: 200,
        body: {
          links: {
            taxons: %w[225df4a8-2945-4e9b-8799-df7424a90b69],
            organisations: %w[20583132-1619-4c68-af24-77583172c070],
          },
        },
      )

    api_client.patch_links(
      content_id,
      links: {
        taxons: %w[225df4a8-2945-4e9b-8799-df7424a90b69],
      },
    )
  end

  it "responds with the links when deleting links of a specific type" do
    publishing_api
      .given("organisation links exist for content_id #{content_id}")
      .upon_receiving("a patch blank organisation links request")
      .with(
        method: :patch,
        path: "/v2/links/#{content_id}",
        body: {
          links: {
            organisations: [],
          },
        },
        headers: {
          "Content-Type" => "application/json",
        },
      )
      .will_respond_with(
        status: 200,
        body: {
          links: {},
        },
      )

    api_client.patch_links(
      content_id,
      links: {
        organisations: [],
      },
    )
  end

  it "responds with the links when there's no links entry" do
    publishing_api
      .given("no links exist for content_id #{content_id}")
      .upon_receiving("a patch organisation links request")
      .with(
        method: :patch,
        path: "/v2/links/#{content_id}",
        body: {
          links: {
            organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
          },
        },
        headers: {
          "Content-Type" => "application/json",
        },
      )
      .will_respond_with(
        status: 200,
        body: {
          links: {
            organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
          },
        },
      )

    api_client.patch_links(
      content_id,
      links: {
        organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
      },
    )
  end

  describe "optimistic locking" do
    it "responds with 200 OK if the linkset has not changed since it was requested" do
      publishing_api
        .given("the linkset for #{content_id} is at version 3")
        .upon_receiving("a request to update the linkset at version 3")
        .with(
          method: :patch,
          path: "/v2/links/#{content_id}",
          body: {
            links: {
              organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
            },
            previous_version: 3,
          },
          headers: {
            "Content-Type" => "application/json",
          },
        )
        .will_respond_with(
          status: 200,
        )

      api_client.patch_links(
        content_id,
        links: {
          organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
        },
        previous_version: 3,
      )
    end

    it "responds with 409 Conflict if the content item has changed in the meantime" do
      publishing_api
          .given("the linkset for #{content_id} is at version 3")
          .upon_receiving("a request to update the linkset at version 2")
          .with(
            method: :patch,
            path: "/v2/links/#{content_id}",
            body: {
              links: {
                organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
              },
              previous_version: 2,
            },
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 409,
            body: {
              "error" => {
                "code" => 409,
                "message" => Pact.term(generate: "Conflict", matcher: /\S+/),
                "fields" => {
                  "previous_version" => Pact.each_like("does not match", min: 1),
                },
              },
            },
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

      assert_raises(GdsApi::HTTPConflict) do
        api_client.patch_links(
          content_id,
          links: {
            organisations: %w[591436ab-c2ae-416f-a3c5-1901d633fbfb],
          },
          previous_version: 2,
        )
      end
    end
  end
end
