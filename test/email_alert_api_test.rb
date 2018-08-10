require 'test_helper'
require 'gds_api/email_alert_api'
require 'gds_api/test_helpers/email_alert_api'

describe GdsApi::EmailAlertApi do
  include GdsApi::TestHelpers::EmailAlertApi

  let(:base_url)      { Plek.find("email-alert-api") }
  let(:api_client)    { GdsApi::EmailAlertApi.new(base_url) }

  let(:title) { "Some Title" }
  let(:tags) {
    {
      "format" => ["some-document-format"],
    }
  }

  describe "alerts" do
    let(:subject) { "Email subject" }
    let(:publication_params) {
      {
        "title" => title,
        "subject" => subject,
        "tags" => tags,
      }
    }

    before do
      email_alert_api_accepts_alert
    end

    it "posts a new alert" do
      assert api_client.send_alert(publication_params)

      assert_requested(:post, "#{base_url}/notifications", body: publication_params.to_json)
    end

    it "returns the an empty response" do
      assert api_client.send_alert(publication_params).to_hash.empty?
    end

    describe "when custom headers are passed in" do
      it "posts a new alert with the custom headers" do
        assert api_client.send_alert(publication_params, govuk_request_id: 'aaaaaaa-1111111')

        assert_requested(:post, "#{base_url}/notifications", body: publication_params.to_json, headers: { 'Govuk-Request-Id' => 'aaaaaaa-1111111' })
      end
    end
  end

  let(:unpublish_message) {
    {
      "content_id" => "content-id"
    }
  }

  describe "unpublishing messages" do
    before do
      email_alert_api_accepts_unpublishing_message
    end

    it "sends an unpublish message" do
      assert api_client.send_unpublish_message(unpublish_message)

      assert_requested(:post, "#{base_url}/unpublish-messages", body: unpublish_message.to_json)
    end
  end

  describe "subscriptions" do
    describe "a subscription exists" do
      before do
        email_alert_api_has_subscription(1, "weekly")
      end

      it "returns the subscription attributes" do
        subscription_attrs = api_client.get_subscription(1)
          .to_hash
          .fetch("subscription")

        assert_equal("weekly", subscription_attrs.fetch("frequency"))
      end
    end
  end

  describe "subscriber lists" do
    let(:expected_subscription_url) { "a subscription url" }

    describe "#find_or_create_subscriber_list_by_tags" do
      let(:params) {
        {
          "title" => title,
          "tags" => tags,
        }
      }

      describe "a subscriber list with that tag set does not yet exist" do
        before do
          email_alert_api_does_not_have_subscriber_list(
            "tags" => tags,
          )

          email_alert_api_creates_subscriber_list(
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
          email_alert_api_has_subscriber_list(
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
        let(:params) {
          {
            "title" => title,
            "tags" => tags,
            "document_type" => "travel_advice",
          }
        }

        before do
          email_alert_api_has_subscriber_list(
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
            subscriber_list_attrs.fetch("document_type")
          )
        end
      end

      describe "when the optional 'email_document_supertype' and 'government_document_supertype' are provided" do
        let(:params) {
          {
            "title" => title,
            "tags" => tags,
            "email_document_supertype" => "publications",
            "government_document_supertype" => "travel_advice",
          }
        }

        before do
          email_alert_api_has_subscriber_list(
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
            subscriber_list_attrs.fetch("email_document_supertype")
          )
          assert_equal(
            "travel_advice",
            subscriber_list_attrs.fetch("government_document_supertype")
          )
        end
      end

      describe "when the optional 'gov_delivery_id' is provided" do
        let(:params) {
          {
            "title" => title,
            "tags" => tags,
            "gov_delivery_id" => "TOPIC-A",
          }
        }

        before do
          email_alert_api_has_subscriber_list(
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
            subscriber_list_attrs.fetch("gov_delivery_id")
          )
        end
      end

      describe "when both tags and links are provided" do
        let(:links) {
          {
            "format" => ["some-document-format"]
          }
        }

        let(:params) {
          {
            "title" => title,
            "tags" => tags,
            "links" => links,
          }
        }

        before do
          email_alert_api_has_subscriber_list(
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
    describe "with an existing subscription" do
      it "returns a 204" do
        uuid = SecureRandom.uuid
        email_alert_api_unsubscribes_a_subscription(uuid)
        api_response = api_client.unsubscribe(uuid)

        assert_equal(
          api_response.code,
          204
        )
      end
    end

    describe "without an existing subscription" do
      it "returns a 404" do
        uuid = SecureRandom.uuid
        email_alert_api_has_no_subscription_for_uuid(uuid)

        assert_raises GdsApi::HTTPNotFound do
          api_client.unsubscribe(uuid)
        end
      end
    end
  end

  describe "unsubscribing from everything" do
    describe "with an existing subscriber" do
      it "returns a 204" do
        subscriber_id = SecureRandom.random_number(10)
        email_alert_api_unsubscribes_a_subscriber(subscriber_id)
        api_response = api_client.unsubscribe_subscriber(subscriber_id)

        assert_equal(
          api_response.code,
          204
        )
      end
    end

    describe "without an existing subscriber" do
      it "returns a 404" do
        subscriber_id = SecureRandom.random_number(10)
        email_alert_api_has_no_subscriber(subscriber_id)

        assert_raises GdsApi::HTTPNotFound do
          api_client.unsubscribe_subscriber(subscriber_id)
        end
      end
    end
  end

  describe "subscribing and a subscription is created" do
    describe "with a frequency specified" do
      it "returns a 201 and the subscription id" do
        subscribable_id = 5
        address = "test@test.com"
        created_subscription_id = 1
        frequency = "daily"

        email_alert_api_creates_a_subscription(
          subscribable_id,
          address,
          frequency,
          created_subscription_id
        )
        api_response = api_client.subscribe(subscribable_id: subscribable_id, address: address, frequency: frequency)
        assert_equal(201, api_response.code)
        assert_equal({ "subscription_id" => 1 }, api_response.to_h)
      end
    end

    describe "without a frequency specified" do
      it "returns a 201 and the subscription id" do
        subscribable_id = 6
        address = "test@test.com"
        created_subscription_id = 1
        frequency = "immediately"

        email_alert_api_creates_a_subscription(
          subscribable_id,
          address,
          frequency,
          created_subscription_id
        )
        api_response = api_client.subscribe(subscribable_id: subscribable_id, address: address)
        assert_equal(201, api_response.code)
        assert_equal({ "subscription_id" => 1 }, api_response.to_h)
      end
    end
  end

  describe "subscribing and a subscription already exists" do
    it "returns a 200 and the subscription id" do
      subscribable_id = 5
      address = "test@test.com"
      existing_subscription_id = 1
      frequency = "immediately"

      email_alert_api_creates_an_existing_subscription(
        subscribable_id,
        address,
        frequency,
        existing_subscription_id
      )
      api_response = api_client.subscribe(subscribable_id: subscribable_id, address: address, frequency: frequency)
      assert_equal(200, api_response.code)
      assert_equal({ "subscription_id" => 1 }, api_response.to_h)
    end
  end

  describe "subscribing with an invalid address" do
    it "raises an unprocessable entity error" do
      email_alert_api_refuses_to_create_subscription(123, "invalid", "weekly")

      assert_raises GdsApi::HTTPUnprocessableEntity do
        api_client.subscribe(subscribable_id: 123, address: "invalid", frequency: "weekly")
      end
    end
  end

  describe "get_subscribable when one exists" do
    it "returns it" do
      email_alert_api_has_subscribable(
        reference: "test123",
        returned_attributes: {
          id: 1,
          gov_delivery_id: "test123",
        }
      )
      api_response = api_client.get_subscribable(reference: "test123")
      assert_equal(200, api_response.code)
      parsed_body = api_response.to_h
      assert_equal(1, parsed_body["subscribable"]["id"])
    end
  end

  describe "get_subscribable when one doesn't exist" do
    it "returns 404" do
      email_alert_api_does_not_have_subscribable(reference: "test123")

      assert_raises GdsApi::HTTPNotFound do
        api_client.get_subscribable(reference: "test123")
      end
    end
  end

  describe "change_subscriber when a subscriber exists" do
    it "changes the subscriber's address" do
      email_alert_api_has_updated_subscriber(1, "test2@example.com")
      api_response = api_client.change_subscriber(
        id: 1,
        new_address: "test2@example.com"
      )
      assert_equal(200, api_response.code)
      parsed_body = api_response.to_h
      assert_equal("test2@example.com", parsed_body["subscriber"]["address"])
    end
  end

  describe "change_subscriber when a subscriber doesn't exist" do
    it "returns 404" do
      email_alert_api_does_not_have_updated_subscriber(1)

      assert_raises GdsApi::HTTPNotFound do
        api_client.change_subscriber(
          id: 1,
          new_address: "test2@example.com"
        )
      end
    end
  end

  describe "change_subscription when a subscription exists" do
    it "changes the subscription's frequency" do
      email_alert_api_has_updated_subscription(
        "8ed841d1-3d20-4633-aaf4-df41deaaf51c",
        "weekly"
      )
      api_response = api_client.change_subscription(
        id: "8ed841d1-3d20-4633-aaf4-df41deaaf51c",
        frequency: "weekly"
      )
      assert_equal(200, api_response.code)
      parsed_body = api_response.to_h
      assert_equal("weekly", parsed_body["subscription"]["frequency"])
    end
  end

  describe "change_subscription when a subscription doesn't exist" do
    it "returns 404" do
      email_alert_api_does_not_have_updated_subscription("8ed841d1-3d20-4633-aaf4-df41deaaf51c")

      assert_raises GdsApi::HTTPNotFound do
        api_client.change_subscription(
          id: "8ed841d1-3d20-4633-aaf4-df41deaaf51c",
          frequency: "weekly"
        )
      end
    end
  end

  describe "get_subscriptions when a subscriber exists" do
    it "returns it" do
      email_alert_api_has_subscriber_subscriptions(1, "test@example.com")
      api_response = api_client.get_subscriptions(id: 1)
      assert_equal(200, api_response.code)
      parsed_body = api_response.to_h
      assert_equal("some-thing", parsed_body["subscriptions"][0]["subscriber_list"]["slug"])
    end
  end

  describe "get_subscriptions when a subscriber doesn't exist" do
    it "returns 404" do
      email_alert_api_does_not_have_subscriber_subscriptions(1)

      assert_raises GdsApi::HTTPNotFound do
        api_client.get_subscriptions(id: 1)
      end
    end
  end

  describe "create an auth token" do
    it "returns 201" do
      email_alert_api_creates_an_auth_token(1, "test@example.com")
      api_response = api_client.create_auth_token(address: 1, destination: "/test")
      assert_equal(201, api_response.code)
    end
  end
end
