require "test_helper"
require "gds_api/email_alert_api"
require "gds_api/test_helpers/email_alert_api"

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
    # TODO: implement pact, used by email-alert-service
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
    # TODO: implement pact, used by account-api
  end

  describe "#subscribe" do
    # TODO: implement pact, used by email-alert-frontend
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
    # TODO: implement pact, used by email-alert-frontend
  end

  describe "#update_subscriber_list_details" do
    # TODO: implement pact, used by email-alert-service
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
        .given("a verified govuk_account_session exists with a matching subscriber")
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
            subscriber: example_subscriber,
          },
          headers: {
            "Content-Type" => "application/json; charset=utf-8",
          },
        )

      api_client.authenticate_subscriber_by_govuk_account(govuk_account_session: "session identifier")
    end
  end

  describe "#find_subscriber_by_govuk_account" do
    # TODO: implement pact, used by account-api
  end

  describe "#link_subscriber_to_govuk_account" do
    # TODO: implement pact, used by email-alert-frontend
  end

  describe "#send_subscriber_verification_email" do
    # TODO: implement pact, used by email-alert-frontend
  end

  describe "#send_subscription_verification_email" do
    # TODO: implement pact, used by email-alert-frontend
  end
end
