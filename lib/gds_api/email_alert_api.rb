require_relative "base"
require_relative "exceptions"

class GdsApi::EmailAlertApi < GdsApi::Base
  def post_notification(notification)
    post_json!(email_alert_api_url, notification)
  end

private

  def email_alert_api_url
    "#{endpoint}/notifications"
  end
end
