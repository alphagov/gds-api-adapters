require "test_helper"
require "gds_api/email_alert_api"
require "gds_api/test_helpers/email_alert_api"

# Note that currently these tests rely on an extension being installed in
# a template database on the CI server (see README.md)

describe GdsApi::EmailAlertApi do
  include GdsApi::TestHelpers::EmailAlertApi
  include PactTest

  let(:api_client) { GdsApi::EmailAlertApi.new(email_alert_api_host) }

  let(:example_subscriber) do
    {
      id: Pact.like(1),
      address: "test@example.com",
      created_at: Pact.like(Time.now),
      updated_at: Pact.like(Time.now),
      govuk_account_id: nil,
    }
  end

  let(:example_subscriber_list) do
    {
      id: Pact.like(1),
      links: {},
      tags: { topics: { any: ["motoring/road_rage"] } },
      document_type: "",
      slug: Pact.like("title-1"),
      title: Pact.like("title 1"),
    }
  end

  describe "find_or_create_subscriber_list" do
    it "responds with the subscriber list" do
      email_alert_api
        .upon_receiving("a request to find or create a subscriber list")
        .with(
          method: :post,
          path: "/subscriber-lists",
          body: {
            title: "new-title",
            tags: { topics: { any: ["motoring/road_rage"] } },
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            subscriber_list: example_subscriber_list.merge(title: "new-title"),
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.find_or_create_subscriber_list(title: "new-title", tags: { topics: { any: ["motoring/road_rage"] } })
    end

    it "responds with the subscriber list with an updated title" do
      email_alert_api
        .given("a subscriber list with the tag topic: motoring/road_rage exists")
        .upon_receiving("a request to find or create a subscriber list")
        .with(
          method: :post,
          path: "/subscriber-lists",
          body: {
            title: "new-title",
            tags: { topics: { any: ["motoring/road_rage"] } },
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            subscriber_list: example_subscriber_list.merge(title: "new-title"),
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.find_or_create_subscriber_list(title: "new-title", tags: { topics: { any: ["motoring/road_rage"] } })
    end
  end

  describe "find_subscriber_list" do
    it "responds with a 404 and a message" do
      email_alert_api
        .upon_receiving("a request for a missing subscriber list")
        .with(
          method: :get,
          path: "/subscriber-lists",
          # Query here is odd because the parser doesn't quite handle
          # the output of Rack::Utils.build_nested_query
          query: { "tags[topics][any][]": ["motoring/road_rage"] },
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 404,
          body: { error: "Could not find the subscriber list" },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      begin
        api_client.find_subscriber_list(tags: { topics: { any: ["motoring/road_rage"] } })
      rescue GdsApi::HTTPNotFound
        # We expect this to throw an exception
      end
    end

    it "responds with the subscriber list" do
      email_alert_api
        .given("a subscriber list with the tag topic: motoring/road_rage exists")
        .upon_receiving("a request for the subscriber list")
        .with(
          method: :get,
          path: "/subscriber-lists",
          # Query here is odd because the parser doesn't quite handle
          # the output of Rack::Utils.build_nested_query
          query: { "tags[topics][any][]": ["motoring/road_rage"] },
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            subscriber_list: example_subscriber_list,
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.find_subscriber_list(tags: { topics: { any: ["motoring/road_rage"] } })
    end
  end

  describe "create_content_change" do
    let(:content_change_headers) do
      GdsApi::JsonClient.default_request_with_json_body_headers.merge(
        "Govuk-Request-Id" => "request-id-1",
      )
    end

    it "responds with a conflict if the change exists" do
      email_alert_api
        .given("a content change with content_id 5fc8fb2b-c0b1-4490-99cb-c987a53afb75 exists")
        .upon_receiving("a conflicting content change")
        .with(
          method: :post,
          path: "/content-changes",
          body: {
            content_id: "5fc8fb2b-c0b1-4490-99cb-c987a53afb75",
            base_path: "government/base_path",
            public_updated_at: Time.new(2022, 1, 1),
          },
          headers: content_change_headers,
        )
        .will_respond_with(
          status: 409,
          body: { error: "Content change already received" },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      begin
        api_client.create_content_change({
          content_id: "5fc8fb2b-c0b1-4490-99cb-c987a53afb75",
          base_path: "government/base_path",
          public_updated_at: Time.new(2022, 1, 1),
        }, content_change_headers)
      rescue StandardError
        # This is intended to fail
      end
    end

    it "accepts the content change" do
      email_alert_api
        .upon_receiving("a valid content change")
        .with(
          method: :post,
          path: "/content-changes",
          body: {
            content_id: "5fc8fb2b-c0b1-4490-99cb-c987a53afb75",
            title: "Email Alert API Pact Tests",
            base_path: "government/base_path",
            change_note: "change note",
            public_updated_at: Time.now,
            email_document_supertype: "email document supertype",
            government_document_supertype: "government document supertype",
            document_type: "document type",
            publishing_app: "publishing app",
            description: "description",
          },
          headers: content_change_headers,
        )
        .will_respond_with(
          status: 202,
          body: { message: "Content change queued for sending" },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.create_content_change({
        content_id: "5fc8fb2b-c0b1-4490-99cb-c987a53afb75",
        title: "Email Alert API Pact Tests",
        base_path: "government/base_path",
        change_note: "change note",
        public_updated_at: Time.now,
        email_document_supertype: "email document supertype",
        government_document_supertype: "government document supertype",
        document_type: "document type",
        publishing_app: "publishing app",
        description: "description",
      }, content_change_headers)
    end
  end

  # describe create_message
  #   TODO: method is DEPRECATED, so remove this when removed
  # end

  # describe "topic_matches" do
  #   Not currently used by anything, so not a priority
  # end

  describe "#bulk_unsubscribe" do
    it "responds with a 404" do
      email_alert_api
        .upon_receiving("the request to bulk unsubscribe a missing subscriber_list")
        .with(
          method: :post,
          path: "/subscriber-lists/missing-subscriber-list/bulk-unsubscribe",
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 404,
        )

      begin
        api_client.bulk_unsubscribe(slug: "missing-subscriber-list")
      rescue GdsApi::HTTPNotFound
        # This is expected
      end
    end

    it "responds with a 409" do
      email_alert_api
        .given("a bulk_unsubscribe message with the sender_message_id b735f541-c29c-4752-b084-c4ddb47aee73 and subscriber_list with slug title-1 exists")
        .upon_receiving("the request to repeat a bulk unsubscribe and email subscribers")
        .with(
          method: :post,
          path: "/subscriber-lists/title-1/bulk-unsubscribe",
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
          body: {
            body: "Goodbye!",
            sender_message_id: "b735f541-c29c-4752-b084-c4ddb47aee73",
          },
        )
        .will_respond_with(
          status: 409,
        )

      begin
        api_client.bulk_unsubscribe(
          slug: "title-1",
          body: "Goodbye!",
          sender_message_id: "b735f541-c29c-4752-b084-c4ddb47aee73",
        )
      rescue GdsApi::HTTPConflict
        # This is expected
      end
    end

    it "responds with a 422" do
      email_alert_api
        .given("a subscriber list with slug title-1 exists")
        .upon_receiving("the request to bulk unsubscribe with a message body but missing IDs")
        .with(
          method: :post,
          path: "/subscriber-lists/title-1/bulk-unsubscribe",
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
          body: { body: "Goodbye!" },
        )
        .will_respond_with(
          status: 422,
        )

      begin
        api_client.bulk_unsubscribe(slug: "title-1", body: "Goodbye!")
      rescue GdsApi::HTTPUnprocessableEntity
        # This is expected
      end
    end

    it "responds with a 202" do
      email_alert_api
        .given("a subscriber list with slug title-1 exists")
        .upon_receiving("the request to bulk unsubscribe an existing subscriber_list")
        .with(
          method: :post,
          path: "/subscriber-lists/title-1/bulk-unsubscribe",
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 202,
        )

      api_client.bulk_unsubscribe(slug: "title-1")
    end
  end

  describe "#unsubscribe" do
    it "responds with a 404" do
      email_alert_api
        .upon_receiving("the request to unsubscribe a missing uuid")
        .with(
          method: :post,
          path: "/unsubscribe/719efe7b-00d0-4168-ac30-99fe6093e3fc",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 404,
        )

      begin
        api_client.unsubscribe("719efe7b-00d0-4168-ac30-99fe6093e3fc")
      rescue GdsApi::HTTPNotFound
        # This is expected
      end
    end

    it "responds with a 204 and an empty body" do
      email_alert_api
        .given("a subscription with the uuid 719efe7b-00d0-4168-ac30-99fe6093e3fc exists")
        .upon_receiving("the request to unsubscribe that uuid")
        .with(
          method: :post,
          path: "/unsubscribe/719efe7b-00d0-4168-ac30-99fe6093e3fc",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 204,
          body: "",
        )

      api_client.unsubscribe("719efe7b-00d0-4168-ac30-99fe6093e3fc")
    end
  end

  describe "#unsubscribe_subscriber" do
    it "responds with a 404" do
      email_alert_api
        .upon_receiving("the request to unsubscribe a missing subscriber")
        .with(
          method: :delete,
          path: "/subscribers/1",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 404,
        )

      begin
        api_client.unsubscribe_subscriber(1)
      rescue GdsApi::HTTPNotFound
        # This is expected
      end
    end

    it "responds with a 204" do
      email_alert_api
        .given("a subscriber exists")
        .upon_receiving("the request to unsubscribe that subscriber")
        .with(
          method: :delete,
          path: "/subscribers/1",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 204,
        )

      api_client.unsubscribe_subscriber(1)
    end
  end

  describe "#subscribe" do
    it "responds with a 422" do
      email_alert_api
        .given("a subscriber list with id 1 exists")
        .upon_receiving("request to subscribe with an invalid frequency")
        .with(
          method: :post,
          path: "/subscriptions",
          body: {
            subscriber_list_id: 1,
            address: "test@example.com",
            frequency: "thrice-fortnightly",
            skip_confirmation_email: true,
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 422,
        )

      begin
        api_client.subscribe(
          subscriber_list_id: 1,
          address: "test@example.com",
          frequency: "thrice-fortnightly",
          skip_confirmation_email: true,
        )
      rescue GdsApi::HTTPUnprocessableEntity
        # This is expected
      end
    end

    it "responds with a 200" do
      email_alert_api
        .given("a subscriber list with id 1 exists")
        .upon_receiving("request to subscribe with a valid frequency")
        .with(
          method: :post,
          path: "/subscriptions",
          body: {
            subscriber_list_id: 1,
            address: "test@example.com",
            frequency: "daily",
            skip_confirmation_email: true,
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 200,
        )

      api_client.subscribe(
        subscriber_list_id: 1,
        address: "test@example.com",
        frequency: "daily",
        skip_confirmation_email: true,
      )
    end
  end

  describe "#get_subscriber_list" do
    it "responds with a 404" do
      email_alert_api
        .upon_receiving("the request to get  a missing subscriber list")
        .with(
          method: :get,
          path: "/subscriber-lists/title-1",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 404,
          body: { error: "Could not find the subscriber list" },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      begin
        api_client.get_subscriber_list(slug: "title-1")
      rescue GdsApi::HTTPNotFound
        # This is expected
      end
    end

    it "responds with a 200 and the subscriber list info" do
      email_alert_api
        .given("a subscriber list with slug title-1 exists")
        .upon_receiving("the request to get that subscriber list")
        .with(
          method: :get,
          path: "/subscriber-lists/title-1",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: { subscriber_list: example_subscriber_list },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.get_subscriber_list(slug: "title-1")
    end
  end

  describe "#get_subscription" do
    it "responds with a 404 and an empty body" do
      email_alert_api
        .upon_receiving("the request to get  a missing subscription")
        .with(
          method: :get,
          path: "/subscriptions/719efe7b-00d0-4168-ac30-99fe6093e3fc",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 404,
        )

      begin
        api_client.get_subscription("719efe7b-00d0-4168-ac30-99fe6093e3fc")
      rescue GdsApi::HTTPNotFound
        # This is expected
      end
    end

    it "responds with a 200 and the subscription info" do
      email_alert_api
        .given("a subscription with the uuid 719efe7b-00d0-4168-ac30-99fe6093e3fc exists")
        .upon_receiving("the request to get that subscription")
        .with(
          method: :get,
          path: "/subscriptions/719efe7b-00d0-4168-ac30-99fe6093e3fc",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            subscription: {
              id: "719efe7b-00d0-4168-ac30-99fe6093e3fc",
              subscriber_list: example_subscriber_list,
              subscriber: example_subscriber,
              ended_at: nil,
              ended_reason: nil,
              frequency: "immediately",
              source: "user_signed_up",
            },
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.get_subscription("719efe7b-00d0-4168-ac30-99fe6093e3fc")
    end
  end

  describe "#get_subscriptions" do
    it "responds with a 404" do
      email_alert_api
        .upon_receiving("the request to get subscriptions for a missing subscriber")
        .with(
          method: :get,
          path: "/subscribers/1/subscriptions",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 404,
        )

      begin
        api_client.get_subscriptions(id: 1)
      rescue GdsApi::HTTPNotFound
        # This is expected
      end
    end

    it "responds with a 200 and the subscription" do
      email_alert_api
        .given("a subscription with the uuid 719efe7b-00d0-4168-ac30-99fe6093e3fc exists")
        .upon_receiving("the request to get subscriptions for that subscriber")
        .with(
          method: :get,
          path: "/subscribers/1/subscriptions",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            subscriber: example_subscriber,
            subscriptions: [{
              id: "719efe7b-00d0-4168-ac30-99fe6093e3fc",
              subscriber_list: example_subscriber_list,
              ended_at: nil,
              ended_reason: nil,
              frequency: "immediately",
              source: "user_signed_up",
            }],
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.get_subscriptions(id: 1)
    end
  end

  describe "#change_subscriber" do
    it "responds with a 404" do
      email_alert_api
        .upon_receiving("a request to change a missing subscriber's email address")
        .with(
          method: :patch,
          path: "/subscribers/1",
          body: {
            new_address: "test2@example.com",
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 404,
        )

      begin
        api_client.change_subscriber(id: 1, new_address: "test2@example.com")
      rescue GdsApi::HTTPNotFound
        # This is expected
      end
    end

    it "responds with the updated subscriber" do
      email_alert_api
        .given("a subscriber exists")
        .upon_receiving("a request to change that subscriber's email address")
        .with(
          method: :patch,
          path: "/subscribers/1",
          body: {
            new_address: "test2@example.com",
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            subscriber: example_subscriber.merge(address: "test2@example.com"),
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.change_subscriber(id: 1, new_address: "test2@example.com")
    end
  end

  describe "#change_subscription" do
    it "responds with a 404" do
      email_alert_api
        .upon_receiving("a request to change the frequency of a missing subscription")
        .with(
          method: :patch,
          path: "/subscriptions/1",
          body: { frequency: "daily" },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 404,
        )

      begin
        api_client.change_subscription(id: 1, frequency: :daily)
      rescue GdsApi::HTTPNotFound
        # This is expected
      end
    end

    it "responds with the updated subscription" do
      email_alert_api
        .given("a subscription with the uuid 719efe7b-00d0-4168-ac30-99fe6093e3fc exists")
        .upon_receiving("a request to change the frequency for that subscription")
        .with(
          method: :patch,
          path: "/subscriptions/719efe7b-00d0-4168-ac30-99fe6093e3fc",
          body: { frequency: "daily" },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            subscription: {
              id: Pact.like("719efe7b-00d0-4168-ac30-99fe6093e3fc"),
              subscriber_list: example_subscriber_list,
              subscriber: example_subscriber,
              ended_at: nil,
              ended_reason: nil,
              frequency: "daily",
              source: "frequency_changed",
            },
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.change_subscription(id: "719efe7b-00d0-4168-ac30-99fe6093e3fc", frequency: :daily)
    end
  end

  describe "#update_subscriber_list_details" do
    it "responds with a 404" do
      email_alert_api
        .upon_receiving("a request to change the title of a missing subscriber list")
        .with(
          method: :patch,
          path: "/subscriber-lists/missing-list",
          body: { title: "Contract Test New Title" },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 404,
        )

      begin
        api_client.update_subscriber_list_details(
          slug: "missing-list",
          params: { title: "Contract Test New Title" },
        )
      rescue GdsApi::HTTPNotFound
        # This is expected
      end
    end

    it "responds with a 404" do
      email_alert_api
        .given("a subscriber list with id 1 exists")
        .upon_receiving("a request to change no params of that subscriber list")
        .with(
          method: :patch,
          path: "/subscriber-lists/title-1",
          body: {},
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 422,
        )

      begin
        api_client.update_subscriber_list_details(
          slug: "title-1",
          params: {},
        )
      rescue GdsApi::HTTPUnprocessableEntity
        # This is expected
      end
    end

    it "responds with the update subscription" do
      email_alert_api
        .given("a subscriber list with slug title-1 exists")
        .upon_receiving("a request to update the title and description of that subscriber list")
        .with(
          method: :patch,
          path: "/subscriber-lists/title-1",
          body: {
            title: "Contract Test New Title",
            description: "Contract Test New Description",
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 200,
          body: { subscriber_list: example_subscriber_list.merge(title: "Contract Test New Title", description: "Contract Test New Description") },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.update_subscriber_list_details(
        slug: "title-1",
        params: {
          title: "Contract Test New Title",
          description: "Contract Test New Description",
        },
      )
    end
  end

  describe "#authenticate_subscriber_by_govuk_account" do
    it "responds with a 403" do
      email_alert_api
        .given("a govuk_account_session exists but isn't verified")
        .upon_receiving("a request to authenticate by the govuk_account_session")
        .with(
          method: :post,
          path: "/subscribers/govuk-account",
          body: { govuk_account_session: "session identifier" },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 403,
        )

      begin
        api_client.authenticate_subscriber_by_govuk_account(govuk_account_session: "session identifier")
      rescue GdsApi::HTTPForbidden
        # This is expected
      end
    end

    it "responds with the subscriber" do
      email_alert_api
        .given("a verified govuk_account_session exists with a linked subscriber")
        .upon_receiving("a request to authenticate by the govuk_account_session")
        .with(
          method: :post,
          path: "/subscribers/govuk-account",
          body: { govuk_account_session: "session identifier" },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            subscriber: example_subscriber.merge("govuk_account_id": "internal-user-id"),
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.authenticate_subscriber_by_govuk_account(govuk_account_session: "session identifier")
    end
  end

  describe "#find_subscriber_by_govuk_account" do
    it "responds with the subscriber" do
      email_alert_api
        .upon_receiving("a request to find by a missing govuk account id")
        .with(
          method: :get,
          path: "/subscribers/govuk-account/internal-user-id",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 404,
        )

      begin
        api_client.find_subscriber_by_govuk_account(govuk_account_id: "internal-user-id")
      rescue GdsApi::HTTPNotFound
        # This is expected
      end
    end

    it "responds with the subscriber" do
      email_alert_api
        .given("a verified govuk_account_session exists with a linked subscriber")
        .upon_receiving("a request to find by that subscriber's govuk account id")
        .with(
          method: :get,
          path: "/subscribers/govuk-account/internal-user-id",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            subscriber: example_subscriber.merge(govuk_account_id: "internal-user-id"),
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.find_subscriber_by_govuk_account(govuk_account_id: "internal-user-id")
    end
  end

  describe "#link_subscriber_to_govuk_account" do
    it "responds with a 401" do
      email_alert_api
        .given("the account api can't find the user by session")
        .upon_receiving("a request to link the subscriber, but with bad session id")
        .with(
          method: :post,
          path: "/subscribers/govuk-account/link",
          body: { govuk_account_session: "bad session identifier" },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 401,
        )

      begin
        api_client.link_subscriber_to_govuk_account(govuk_account_session: "bad session identifier")
      rescue GdsApi::HTTPUnauthorized
        # This is expected
      end
    end

    it "responds with a 403" do
      email_alert_api
        .given("a govuk_account_session exists but isn't verified")
        .upon_receiving("a request to link the subscriber")
        .with(
          method: :post,
          path: "/subscribers/govuk-account/link",
          body: { govuk_account_session: "session identifier" },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 403,
        )

      begin
        api_client.link_subscriber_to_govuk_account(govuk_account_session: "session identifier")
      rescue GdsApi::HTTPForbidden
        # This is expected
      end
    end

    it "responds with the subscriber linked" do
      email_alert_api
        .given("a verified govuk_account_session exists with a matching subscriber")
        .upon_receiving("a request to link the subscriber")
        .with(
          method: :post,
          path: "/subscribers/govuk-account/link",
          body: { govuk_account_session: "session identifier" },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 200,
          body: {
            subscriber: example_subscriber.merge("govuk_account_id": "internal-user-id"),
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.link_subscriber_to_govuk_account(govuk_account_session: "session identifier")
    end
  end

  describe "#send_subscriber_verification_email" do
    # TODO: implement pact, used by email-alert-frontend
  end

  describe "#send_subscription_verification_email" do
    # TODO: implement pact, used by email-alert-frontend
  end
end
