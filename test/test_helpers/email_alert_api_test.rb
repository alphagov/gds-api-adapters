require "test_helper"
require "gds_api/email_alert_api"
require "gds_api/test_helpers/email_alert_api"

describe GdsApi::TestHelpers::EmailAlertApi do
  include GdsApi::TestHelpers::EmailAlertApi

  let(:base_api_url) { Plek.current.find("email-alert-api") }
  let(:email_alert_api) { GdsApi::EmailAlertApi.new(base_api_url) }

  describe "#assert_email_alert_api_content_change_created" do
    before { stub_any_email_alert_api_call }

    it "matches a post request with any empty attributes by default" do
      email_alert_api.create_content_change("foo" => "bar")
      assert_email_alert_api_content_change_created
    end

    it "matches a post request subset of attributes" do
      email_alert_api.create_content_change("foo" => "bar", "baz" => "qux")
      assert_email_alert_api_content_change_created("foo" => "bar")
    end
  end

  describe "#assert_email_alert_api_message_created" do
    before { stub_any_email_alert_api_call }

    it "matches a post request with any empty attributes by default" do
      email_alert_api.create_message("foo" => "bar")
      assert_email_alert_api_message_created
    end

    it "matches a post request subset of attributes" do
      email_alert_api.create_message("foo" => "bar", "baz" => "qux")
      assert_email_alert_api_message_created("foo" => "bar")
    end
  end

  describe "#stub_email_alert_api_has_subscriber_subscriptions" do
    let(:id) { SecureRandom.uuid }
    let(:address) { "test@example.com" }

    it "stubs with a single subscription by default" do
      stub_email_alert_api_has_subscriber_subscriptions(id, address)
      result = email_alert_api.get_subscriptions(id: id)
      assert_equal(1, result["subscriptions"].count)
    end

    it "stubs subscriptions with an optional ordering" do
      stub_email_alert_api_has_subscriber_subscriptions(id, address, "-title")
      result = email_alert_api.get_subscriptions(id: id, order: "-title")
      assert_equal(1, result["subscriptions"].count)
    end

    it "stubs subscriptions with specific ones" do
      stub_email_alert_api_has_subscriber_subscriptions(
        id,
        address,
        subscriptions: %w(one two),
      )

      result = email_alert_api.get_subscriptions(id: id)
      assert_equal(2, result["subscriptions"].count)
    end
  end
end
