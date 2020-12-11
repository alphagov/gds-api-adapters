require "test_helper"
require "gds_api/email_alert_api"
require "gds_api/test_helpers/email_alert_api"

describe GdsApi::EmailAlertApi do
  include GdsApi::TestHelpers::EmailAlertApi

  let(:base_url)      { Plek.find("email-alert-api") }
  let(:api_client)    { GdsApi::EmailAlertApi.new(base_url) }

  let(:title) { "Some Title" }
  let(:tags) do
    {
      "format" => %w[some-document-format],
    }
  end

  describe "content changes" do
    let(:subject) { "Email subject" }
    let(:publication_params) do
      {
        "title" => title,
        "subject" => subject,
        "tags" => tags,
      }
    end

    before do
      stub_email_alert_api_accepts_content_change
    end

    it "posts a new alert" do
      assert api_client.create_content_change(publication_params)

      assert_requested(:post, "#{base_url}/content-changes", body: publication_params.to_json)
    end

    it "returns the an empty response" do
      assert api_client.create_content_change(publication_params).to_hash.empty?
    end

    describe "when custom headers are passed in" do
      it "posts a new alert with the custom headers" do
        assert api_client.create_content_change(publication_params, govuk_request_id: "aaaaaaa-1111111")

        assert_requested(:post, "#{base_url}/content-changes", body: publication_params.to_json, headers: { "Govuk-Request-Id" => "aaaaaaa-1111111" })
      end
    end
  end

  describe "messages" do
    let(:subject) { "Email subject" }
    let(:message_params) do
      {
        "subject" => subject,
        "body" => "Body",
        "tags" => tags,
      }
    end

    before do
      stub_email_alert_api_accepts_message
    end

    it "posts a new message" do
      assert api_client.create_message(message_params)

      assert_requested(:post, "#{base_url}/messages", body: message_params.to_json)
    end

    it "returns the an empty response" do
      assert api_client.create_message(message_params).to_hash.empty?
    end
  end

  it "posts a new email" do
    stub_email_alert_api_accepts_email
    email_params = { address: "test@test.com", subject: "Subject", body: "Description of thing" }

    assert api_client.create_email(email_params)

    assert_requested(:post, "#{base_url}/emails", body: email_params.to_json)
  end

  let(:unpublish_message) do
    {
      "content_id" => "content-id",
    }
  end

  describe "unpublishing messages" do
    before do
      stub_email_alert_api_accepts_unpublishing_message
    end

    it "sends an unpublish message" do
      assert api_client.send_unpublish_message(unpublish_message)

      assert_requested(:post, "#{base_url}/unpublish-messages", body: unpublish_message.to_json)
    end
  end

  describe "subscriptions" do
    describe "URI encoding ids" do
      it "encodes the id for #get_subscription" do
        request = stub_request(:get, "#{base_url}/subscriptions/string%20id")
        api_client.get_subscription("string id")
        assert_requested request
      end

      it "encodes the id for #get_latest_matching_subscription" do
        request = stub_request(:get, "#{base_url}/subscriptions/string%20id/latest")
        api_client.get_latest_matching_subscription("string id")
        assert_requested request
      end
    end

    describe "a subscription exists" do
      before do
        stub_email_alert_api_has_subscription(1, "weekly")
      end

      it "returns the subscription attributes" do
        subscription_attrs = api_client.get_subscription(1)
          .to_hash
          .fetch("subscription")

        assert_equal("weekly", subscription_attrs.fetch("frequency"))
      end

      it "returns the subscription attributes on /latest" do
        subscription_attrs = api_client.get_latest_matching_subscription(1)
          .to_hash
          .fetch("subscription")

        assert_equal(1, subscription_attrs.fetch("id"))
      end
    end

    describe "user unsubscribed then resubscribed at the same frequency" do
      before do
        stub_email_alert_api_has_subscriptions([
          {
            id: 1,
            frequency: "weekly",
            ended: true,
          },
          {
            id: 2000,
            frequency: "weekly",
          },
        ])
      end

      it "returns the latest subscription attributes on /latest" do
        subscription_attrs = api_client.get_latest_matching_subscription(1)
          .to_hash
          .fetch("subscription")

        assert_equal(2000, subscription_attrs.fetch("id"))
      end
    end

    describe "user changed their frequency then unsubscribed altogether" do
      before do
        stub_email_alert_api_has_subscriptions([
          {
            id: 1,
            frequency: "weekly",
            ended: true,
          },
          {
            id: 2000,
            frequency: "daily",
            ended: true,
          },
        ])
      end

      it "returns the latest subscription attributes on /latest" do
        subscription_attrs = api_client.get_latest_matching_subscription(1)
          .to_hash
          .fetch("subscription")

        assert_equal(2000, subscription_attrs.fetch("id"))
      end
    end

    describe "user is subscribed to multiple lists" do
      before do
        stub_email_alert_api_has_subscriptions([
          {
            id: 1,
            frequency: "weekly",
            subscriber_list_id: 123,
          },
          {
            id: 2,
            frequency: "weekly",
            subscriber_list_id: 456,
          },
        ])
      end

      it "returns the correct subscriber list on /latest" do
        first_subscription_attrs = api_client.get_latest_matching_subscription(1)
          .to_hash
          .fetch("subscription")
        second_subscription_attrs = api_client.get_latest_matching_subscription(2)
          .to_hash
          .fetch("subscription")

        assert_equal(1, first_subscription_attrs.fetch("id"))
        assert_equal(2, second_subscription_attrs.fetch("id"))
      end
    end
  end

  describe "subscriber lists" do
    let(:expected_subscription_url) { "a subscription url" }

    describe "#find_or_create_subscriber_list_by_tags" do
      let(:params) do
        {
          "title" => title,
          "tags" => tags,
        }
      end

      describe "a subscriber list with that tag set does not yet exist" do
        before do
          stub_email_alert_api_does_not_have_subscriber_list(
            "tags" => tags,
          )

          stub_email_alert_api_creates_subscriber_list(
            "title" => title,
            "tags" => tags,
            "subscription_url" => expected_subscription_url,
          )
        end

        it "creates the list and returns its attributes" do
          subscriber_list_attrs = api_client.find_or_create_subscriber_list(params)
            .to_hash
            .fetch("subscriber_list")

          assert_equal(
            expected_subscription_url,
            subscriber_list_attrs.fetch("subscription_url"),
          )

          assert_equal(
            42,
            subscriber_list_attrs.fetch("active_subscriptions_count"),
          )
        end
      end

      describe "a subscriber list with that tag set does already exist" do
        before do
          stub_email_alert_api_has_subscriber_list(
            "title" => "Some Title",
            "tags" => tags,
            "subscription_url" => expected_subscription_url,
          )
        end

        it "returns the subscriber list attributes" do
          subscriber_list_attrs = api_client.find_or_create_subscriber_list(params)
            .to_hash
            .fetch("subscriber_list")

          assert_equal(
            expected_subscription_url,
            subscriber_list_attrs.fetch("subscription_url"),
          )
        end
      end

      describe "when the optional 'document_type' is provided" do
        let(:params) do
          {
            "title" => title,
            "tags" => tags,
            "document_type" => "travel_advice",
          }
        end

        before do
          stub_email_alert_api_has_subscriber_list(
            "title" => "Some Title",
            "tags" => tags,
            "document_type" => "travel_advice",
            "subscription_url" => expected_subscription_url,
          )
        end

        it "returns the subscriber list attributes" do
          subscriber_list_attrs = api_client.find_or_create_subscriber_list(params)
            .to_hash
            .fetch("subscriber_list")

          assert_equal(
            "travel_advice",
            subscriber_list_attrs.fetch("document_type"),
          )
        end
      end

      describe "when the optional 'email_document_supertype' and 'government_document_supertype' are provided" do
        let(:params) do
          {
            "title" => title,
            "tags" => tags,
            "email_document_supertype" => "publications",
            "government_document_supertype" => "travel_advice",
          }
        end

        before do
          stub_email_alert_api_has_subscriber_list(
            "title" => "Some Title",
            "tags" => tags,
            "email_document_supertype" => "publications",
            "government_document_supertype" => "travel_advice",
            "subscription_url" => expected_subscription_url,
          )
        end

        it "returns the subscriber list attributes" do
          subscriber_list_attrs = api_client.find_or_create_subscriber_list(params)
            .to_hash
            .fetch("subscriber_list")

          assert_equal(
            "publications",
            subscriber_list_attrs.fetch("email_document_supertype"),
          )
          assert_equal(
            "travel_advice",
            subscriber_list_attrs.fetch("government_document_supertype"),
          )
        end
      end

      describe "when the optional 'gov_delivery_id' is provided" do
        let(:params) do
          {
            "title" => title,
            "tags" => tags,
            "gov_delivery_id" => "TOPIC-A",
          }
        end

        before do
          stub_email_alert_api_has_subscriber_list(
            "title" => "Some Title",
            "tags" => tags,
            "gov_delivery_id" => "TOPIC-A",
            "subscription_url" => expected_subscription_url,
          )
        end

        it "returns the subscriber list attributes" do
          subscriber_list_attrs = api_client.find_or_create_subscriber_list(params)
            .to_hash
            .fetch("subscriber_list")

          assert_equal(
            "TOPIC-A",
            subscriber_list_attrs.fetch("gov_delivery_id"),
          )
        end
      end

      describe "when both tags and links are provided" do
        let(:links) do
          {
            "format" => %w[some-document-format],
          }
        end

        let(:params) do
          {
            "title" => title,
            "tags" => tags,
            "links" => links,
          }
        end

        before do
          stub_email_alert_api_has_subscriber_list(
            "title" => "Some Title",
            "tags" => tags,
            "links" => links,
            "subscription_url" => expected_subscription_url,
          )
        end

        it "excludes that attribute from the query string" do
          assert_raises do
            api_client.find_or_create_subscriber_list(params)
          end
        end
      end
    end
  end

  describe "unsubscribing from a topic" do
    it "URI encodes the id" do
      request = stub_email_alert_api_unsubscribes_a_subscription("string%20id")
      api_client.unsubscribe("string id")
      assert_requested request
    end

    describe "with an existing subscription" do
      it "returns a 204" do
        uuid = SecureRandom.uuid
        stub_email_alert_api_unsubscribes_a_subscription(uuid)
        api_response = api_client.unsubscribe(uuid)

        assert_equal(
          api_response.code,
          204,
        )
      end
    end

    describe "without an existing subscription" do
      it "returns a 404" do
        uuid = SecureRandom.uuid
        stub_email_alert_api_has_no_subscription_for_uuid(uuid)

        assert_raises GdsApi::HTTPNotFound do
          api_client.unsubscribe(uuid)
        end
      end
    end
  end

  describe "unsubscribing from everything" do
    it "URI encodes the id" do
      request = stub_email_alert_api_unsubscribes_a_subscriber("string%20id")
      api_client.unsubscribe_subscriber("string id")
      assert_requested request
    end

    describe "with an existing subscriber" do
      it "returns a 204" do
        subscriber_id = SecureRandom.random_number(10)
        stub_email_alert_api_unsubscribes_a_subscriber(subscriber_id)
        api_response = api_client.unsubscribe_subscriber(subscriber_id)

        assert_equal(
          api_response.code,
          204,
        )
      end
    end

    describe "without an existing subscriber" do
      it "returns a 404" do
        subscriber_id = SecureRandom.random_number(10)
        stub_email_alert_api_has_no_subscriber(subscriber_id)

        assert_raises GdsApi::HTTPNotFound do
          api_client.unsubscribe_subscriber(subscriber_id)
        end
      end
    end
  end

  describe "subscribing and a subscription is created" do
    describe "with a frequency specified" do
      it "returns a 200 and the subscription id" do
        subscriber_list_id = 5
        address = "test@test.com"
        created_subscription_id = 1
        frequency = "daily"

        stub_email_alert_api_creates_a_subscription(
          subscriber_list_id,
          address,
          frequency,
          created_subscription_id,
        )
        api_response = api_client.subscribe(subscriber_list_id: subscriber_list_id, address: address, frequency: frequency)
        assert_equal(200, api_response.code)
        parsed_body = api_response.to_h
        assert_equal(created_subscription_id, parsed_body["subscription"]["id"])
      end
    end

    describe "without a frequency specified" do
      it "returns a 200 and the subscription id" do
        subscriber_list_id = 6
        address = "test@test.com"
        created_subscription_id = 1
        frequency = "immediately"

        stub_email_alert_api_creates_a_subscription(
          subscriber_list_id,
          address,
          frequency,
          created_subscription_id,
        )
        api_response = api_client.subscribe(subscriber_list_id: subscriber_list_id, address: address)
        assert_equal(200, api_response.code)
        parsed_body = api_response.to_h
        assert_equal(created_subscription_id, parsed_body["subscription"]["id"])
      end
    end

    describe "without a confirmation email" do
      it "returns a 200 and the subscription id" do
        subscriber_list_id = 6
        address = "test@test.com"
        created_subscription_id = 1
        frequency = "immediately"

        stub_email_alert_api_creates_a_subscription(
          subscriber_list_id,
          address,
          frequency,
          created_subscription_id,
          skip_confirmation_email: true,
        )

        api_response = api_client.subscribe(
          subscriber_list_id: subscriber_list_id,
          address: address,
          skip_confirmation_email: true,
        )

        assert_equal(200, api_response.code)
        parsed_body = api_response.to_h
        assert_equal(created_subscription_id, parsed_body["subscription"]["id"])
      end
    end
  end

  describe "subscribing with an invalid address" do
    it "raises an unprocessable entity error" do
      subscriber_list_id = 123
      address = "invalid"
      frequency = "weekly"

      stub_email_alert_api_refuses_to_create_subscription(
        subscriber_list_id,
        address,
        frequency,
      )

      assert_raises GdsApi::HTTPUnprocessableEntity do
        api_client.subscribe(subscriber_list_id: 123, address: "invalid", frequency: "weekly")
      end
    end
  end

  describe "get_subscriber_list with a slug that required URI encoding" do
    it "encodes the slug" do
      request = stub_email_alert_api_has_subscriber_list_by_slug(slug: "needs%20encoding",
                                                                 returned_attributes: {})
      api_client.get_subscriber_list(slug: "needs encoding")
      assert_requested request
    end
  end

  describe "get_subscriber_list when one exists" do
    it "returns it" do
      stub_email_alert_api_has_subscriber_list_by_slug(
        slug: "test123",
        returned_attributes: {
          id: 1,
          gov_delivery_id: "test123",
        },
      )
      api_response = api_client.get_subscriber_list(slug: "test123")
      assert_equal(200, api_response.code)
      parsed_body = api_response.to_h
      assert_equal(1, parsed_body["subscriber_list"]["id"])
    end
  end

  describe "get_subscriber_list when one doesn't exist" do
    it "returns 404" do
      stub_email_alert_api_does_not_have_subscriber_list_by_slug(slug: "test123")

      assert_raises GdsApi::HTTPNotFound do
        api_client.get_subscriber_list(slug: "test123")
      end
    end
  end

  describe "change_subscriber with an id that needs URI encoding" do
    it "encodes the id" do
      request = stub_email_alert_api_has_updated_subscriber("string%20id", "test2@example.com")
      api_client.change_subscriber(id: "string id", new_address: "test2@example.com")
      assert_requested request
    end
  end

  describe "change_subscriber when a subscriber exists" do
    it "changes the subscriber's address" do
      stub_email_alert_api_has_updated_subscriber(1, "test2@example.com")
      api_response = api_client.change_subscriber(
        id: 1,
        new_address: "test2@example.com",
      )
      assert_equal(200, api_response.code)
      parsed_body = api_response.to_h
      assert_equal("test2@example.com", parsed_body["subscriber"]["address"])
    end
  end

  describe "change_subscriber when a subscriber doesn't exist" do
    it "returns 404" do
      stub_email_alert_api_does_not_have_updated_subscriber(1)

      assert_raises GdsApi::HTTPNotFound do
        api_client.change_subscriber(
          id: 1,
          new_address: "test2@example.com",
        )
      end
    end
  end

  describe "change_subscription with an id that needs URI encoding" do
    it "encodes the id" do
      request = stub_email_alert_api_has_updated_subscription("string%20id", "weekly")
      api_client.change_subscription(id: "string id", frequency: "weekly")
      assert_requested request
    end
  end

  describe "change_subscription when a subscription exists" do
    it "changes the subscription's frequency" do
      stub_email_alert_api_has_updated_subscription(
        "8ed841d1-3d20-4633-aaf4-df41deaaf51c",
        "weekly",
      )
      api_response = api_client.change_subscription(
        id: "8ed841d1-3d20-4633-aaf4-df41deaaf51c",
        frequency: "weekly",
      )
      assert_equal(200, api_response.code)
      parsed_body = api_response.to_h
      assert_equal("weekly", parsed_body["subscription"]["frequency"])
    end
  end

  describe "change_subscription when a subscription doesn't exist" do
    it "returns 404" do
      stub_email_alert_api_does_not_have_updated_subscription("8ed841d1-3d20-4633-aaf4-df41deaaf51c")

      assert_raises GdsApi::HTTPNotFound do
        api_client.change_subscription(
          id: "8ed841d1-3d20-4633-aaf4-df41deaaf51c",
          frequency: "weekly",
        )
      end
    end
  end

  describe "get_subscriptions with parameters that require URI encoding" do
    it "encodes an id parameter" do
      request = stub_email_alert_api_has_subscriber_subscriptions("string%20id", "test@example.com")
      api_client.get_subscriptions(id: "string id")
      assert_requested request
    end

    it "encodes an order parameter" do
      request = stub_email_alert_api_has_subscriber_subscriptions(1, "test@example.com", "order%20param")
      api_client.get_subscriptions(id: 1, order: "order param")
      assert_requested request
    end
  end

  describe "get_subscriptions when a subscriber exists" do
    it "returns it" do
      stub_email_alert_api_has_subscriber_subscriptions(1, "test@example.com", "-title")
      api_response = api_client.get_subscriptions(id: 1, order: "-title")
      assert_equal(200, api_response.code)
      parsed_body = api_response.to_h
      assert_equal("some-thing", parsed_body["subscriptions"][0]["subscriber_list"]["slug"])
    end
  end

  describe "get_subscriptions when a subscriber doesn't exist" do
    it "returns 404" do
      stub_email_alert_api_does_not_have_subscriber_subscriptions(1)

      assert_raises GdsApi::HTTPNotFound do
        api_client.get_subscriptions(id: 1)
      end
    end
  end

  describe "send_subscription_verification_email" do
    it "returns 200" do
      stub_email_alert_api_sends_subscription_verification_email("test@example.com", "immediately", "topic")
      api_response = api_client.send_subscription_verification_email(address: "test@example.com", frequency: "immediately", topic_id: "topic")
      assert_equal(200, api_response.code)
    end
  end

  describe "send_subscriber_verification_email" do
    it "returns 201" do
      stub_email_alert_api_sends_subscriber_verification_email(1, "test@example.com")
      api_response = api_client.send_subscriber_verification_email(address: 1, destination: "/test")
      assert_equal(201, api_response.code)
    end
  end
end
