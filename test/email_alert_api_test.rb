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
  describe "notifications" do
    it "retrieves notifications" do
      stubbed_request = email_alert_api_has_notifications([
        { "subject" => "Foo" }, { "subject" => "Bar" }
      ])
      api_client.notifications
      assert_requested(stubbed_request)
    end

    it "uses the start_at param if present" do
      stubbed_request = email_alert_api_has_notifications([
        { "subject" => "Foo" }, { "subject" => "Bar" }
      ], "101AA")
      api_client.notifications("101AA")
      assert_requested(stubbed_request)
    end
  end

  describe "notification" do
    before do
      @stubbed_request = email_alert_api_has_notification("web_service_bulletin" => { "to_param" => "10001001" })
    end
    it "retrieves a notification by id" do
      api_client.notification("10001001")
      assert_requested(@stubbed_request)
    end
  end
end
