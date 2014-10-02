require 'test_helper'
require 'gds_api/email_alert_api'
require 'gds_api/test_helpers/email_alert_api'

describe GdsApi::EmailAlertApi do
  include GdsApi::TestHelpers::EmailAlertApi

  let(:base_url)      { "http://some-domain" }
  let(:api_client)    { GdsApi::EmailAlertApi.new(base_url) }

  describe "subscriber lists" do
    let(:title) { "Some Title" }
    let(:tags) {
      {
        "format" => ["some-document-format"],
      }
    }
    let(:path){ "/subscriber_lists" }
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
    end

    describe "#create_subscriber_list" do
      let(:params) {
        {
          "title" => title,
          "tags" => tags,
        }
      }

      before do
        email_alert_api_creates_subscriber_list(
          "title" => title,
          "tags" => tags,
          "subscription_url" => expected_subscription_url,
        )
      end

      describe "with valid attributes" do
        it "creates the list and returns its attributes" do
          subscriber_list_attrs = api_client.create_subscriber_list(params)
            .to_hash
            .fetch("subscriber_list")

          assert_equal(
            expected_subscription_url,
            subscriber_list_attrs.fetch("subscription_url"),
          )
        end
      end

      describe "with invalid attributes or list with tag set exists" do
        before do
          email_alert_api_refuses_to_create_subscriber_list
        end

        it "raises ClientError" do
          assert_raises(GdsApi::HTTPClientError) {
            api_client.create_subscriber_list(params)
          }
        end
      end
    end

    describe "#search_subscriber_list_by_tags" do
      let(:path) { "/subscriber_lists" }

      describe "a subscriber list with that tag set already exists" do
        before do
          email_alert_api_has_subscriber_list(
            "title" => "Some Title",
            "tags" => tags,
            "subscription_url" => expected_subscription_url,
          )
        end

        it "returns the subscriber list attributes" do
          subscriber_list_attrs = api_client.search_subscriber_list_by_tags(tags)
            .to_hash
            .fetch("subscriber_list")

          assert_equal(
            expected_subscription_url,
            subscriber_list_attrs.fetch("subscription_url"),
          )
        end
      end

      describe "a subscriber list with that tag set does not exist" do
        before do
          email_alert_api_does_not_have_subscriber_list(
            "tags" => tags,
          )
        end

        it "raises" do
          assert_raises(GdsApi::HTTPNotFound) {
            api_client.search_subscriber_list_by_tags(tags)
          }
        end
      end
    end
  end
end
