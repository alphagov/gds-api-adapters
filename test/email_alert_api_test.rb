require "test_helper"
require "gds_api/email_alert_api"
require "gds_api/test_helpers/email_alert_api_helpers"

describe GdsApi::EmailAlertApi do
  include GdsApi::TestHelpers::EmailAlertApi

  before do
    @endpoint = Plek.find("email-alert-api")
    @email_alert_api = GdsApi::EmailAlertApi.new(@endpoint)
  end

  describe "post notification" do
    it "should post the notification" do
      notification = { title: "test notification" }
      request = stub_email_alert_api_post_notification(notification)
      @email_alert_api.post_notification(notification)
      assert_requested request
    end
  end
end
