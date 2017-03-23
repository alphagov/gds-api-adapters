require 'gds_api/test_helpers/json_client_helper'
require 'json'

module GdsApi
  module TestHelpers
    module EmailAlertApi
      EMAIL_ALERT_API_ENDPOINT = Plek.find("email-alert-api")

      def email_alert_api_has_subscriber_list(attributes)
        stub_request(:get, subscriber_lists_url(attributes))
          .to_return(
            status: 200,
            body: get_subscriber_list_response(attributes).to_json,
          )
      end

      def email_alert_api_does_not_have_subscriber_list(attributes)
        stub_request(:get, subscriber_lists_url(attributes))
          .to_return(status: 404)
      end

      def email_alert_api_creates_subscriber_list(attributes)
        stub_request(:post, subscriber_lists_url)
          .to_return(
            status: 201,
            body: get_subscriber_list_response(attributes).to_json,
          )
      end

      def email_alert_api_refuses_to_create_subscriber_list
        stub_request(:post, subscriber_lists_url)
          .to_return(
            status: 422,
          )
      end

      def get_subscriber_list_response(attributes)
        {
          "subscriber_list" => {
            "id" => "447135c3-07d6-4c3a-8a3b-efa49ef70e52",
            "subscription_url" => "https://stage-public.govdelivery.com/accounts/UKGOVUK/subscriber/new?topic_id=UKGOVUK_1234",
            "gov_delivery_id" => "UKGOVUK_1234",
            "title" => "Some title",
          }.merge(attributes)
        }
      end

      def email_alert_api_accepts_alert
        stub_request(:post, notifications_url)
          .to_return(
            status: 202,
            body: {}.to_json,
          )
      end

      def post_alert_response
        {}
      end

      def stub_any_email_alert_api_call
        stub_request(:any, %r{\A#{EMAIL_ALERT_API_ENDPOINT}})
      end

      def assert_email_alert_sent(attributes = nil)
        if attributes
          matcher = ->(request) do
            payload = JSON.parse(request.body)
            payload.select { |k, _| attributes.key?(k) } == attributes
          end
        end

        assert_requested(:post, notifications_url, times: 1, &matcher)
      end

      def email_alert_api_has_notifications(notifications, start_at = nil)
        url = notifications_url
        url += "?start_at=#{start_at}" if start_at
        url_regexp = Regexp.new("^#{Regexp.escape(url)}$")

        stub_request(:get, url_regexp)
          .to_return(
            status: 200,
            body: notifications.to_json
          )
      end

      def email_alert_api_has_notification(notification)
        url = "#{notifications_url}/#{notification['web_service_bulletin']['to_param']}"

        stub_request(:get, url).to_return(
          status: 200,
          body: notification.to_json
        )
      end

    private

      def subscriber_lists_url(attributes = nil)
        if attributes
          tags = attributes["tags"]
          links = attributes["links"]
          document_type = attributes["document_type"]
          email_document_supertype = attributes["email_document_supertype"]
          government_document_supertype = attributes["government_document_supertype"]
          gov_delivery_id = attributes["gov_delivery_id"]

          params = {}
          params[:tags] = tags if tags
          params[:links] = links if links
          params[:document_type] = document_type if document_type
          params[:email_document_supertype] = email_document_supertype if email_document_supertype
          params[:government_document_supertype] = government_document_supertype if government_document_supertype
          params[:gov_delivery_id] = gov_delivery_id if gov_delivery_id

          query = Rack::Utils.build_nested_query(params)
        end

        url = EMAIL_ALERT_API_ENDPOINT + "/subscriber-lists"
        query ? "#{url}?#{query}" : url
      end

      def notifications_url
        EMAIL_ALERT_API_ENDPOINT + "/notifications"
      end
    end
  end
end
