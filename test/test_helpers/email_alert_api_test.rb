require "test_helper"
require "gds_api/email_alert_api"
require "gds_api/test_helpers/email_alert_api"

describe GdsApi::TestHelpers::EmailAlertApi do
  include GdsApi::TestHelpers::EmailAlertApi

  let(:base_api_url) { Plek.find("email-alert-api") }
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

  describe "#stub_email_alert_api_has_subscriber_subscriptions" do
    let(:id) { SecureRandom.uuid }
    let(:address) { "test@example.com" }

    it "stubs with a single subscription by default" do
      stub_email_alert_api_has_subscriber_subscriptions(id, address)
      result = email_alert_api.get_subscriptions(id:)
      assert_equal(1, result["subscriptions"].count)
    end

    it "stubs subscriptions with an optional ordering" do
      stub_email_alert_api_has_subscriber_subscriptions(id, address, "-title")
      result = email_alert_api.get_subscriptions(id:, order: "-title")
      assert_equal(1, result["subscriptions"].count)
    end

    it "stubs subscriptions with specific ones" do
      stub_email_alert_api_has_subscriber_subscriptions(
        id,
        address,
        subscriptions: %w[one two],
      )

      result = email_alert_api.get_subscriptions(id:)
      assert_equal(2, result["subscriptions"].count)
    end
  end

  describe "#stub_get_subscriber_list_metrics_not_found" do
    it "raises 404" do
      stub_get_subscriber_list_metrics_not_found(path: "/some/path")
      assert_raises(GdsApi::HTTPNotFound) do
        email_alert_api.get_subscriber_list_metrics(path: "/some/path")
      end
    end
  end

  describe "#stub_get_subscriber_list_metrics" do
    it "returns the stubbed data" do
      json = { subscriber_list_count: 3, all_notify_count: 10 }.to_json
      stub_get_subscriber_list_metrics(path: "/some/path", response: json)
      response = email_alert_api.get_subscriber_list_metrics(path: "/some/path")
      expected = { "subscriber_list_count" => 3, "all_notify_count" => 10 }
      assert_equal 200, response.code
      assert_equal expected, response.to_h
    end
  end
end
