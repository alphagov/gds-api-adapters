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
end
