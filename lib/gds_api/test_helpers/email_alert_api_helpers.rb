require "gds_api/test_helpers/json_client_helper"

module GdsApi
  module TestHelpers
    module EmailAlertApi

      EMAIL_ALERT_API_ENDPOINT = Plek.find("email-alert-api")

      def stub_email_alert_api_post_notification(notification)
        url = EMAIL_ALERT_API_ENDPOINT + "/notifications"
        body = {}.to_json
        stub_request(:post, url).
          with(body: notification.to_json).
          to_return(status: 202, body: body, headers: {})
      end
    end
  end
end
