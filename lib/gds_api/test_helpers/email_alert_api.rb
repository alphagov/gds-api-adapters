require 'gds_api/test_helpers/json_client_helper'
require 'json'

module GdsApi
  module TestHelpers
    module EmailAlertApi
      EMAIL_ALERT_API_ENDPOINT = Plek.find("email-alert-api")

      def email_alert_api_has_subscriber_list(attributes)
        stub_request(:get, subscriber_lists_url(attributes))
          .to_return(
            :status => 200,
            :body => get_subscriber_list_response(attributes).to_json,
          )
      end

      def email_alert_api_does_not_have_subscriber_list(attributes)
        stub_request(:get, subscriber_lists_url(attributes))
          .to_return(status: 404)
      end

      def email_alert_api_creates_subscriber_list(attributes)
        stub_request(:post, subscriber_lists_url)
          .to_return(
            :status => 201,
            :body => get_subscriber_list_response(attributes).to_json,
          )
      end

      def email_alert_api_refuses_to_create_subscriber_list
        stub_request(:post, subscriber_lists_url)
          .to_return(
            :status => 422,
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
            :status => 202,
            :body => {}.to_json,
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
        else
          matcher = nil
        end

        assert_requested(:post, notifications_url, times: 1, &matcher)
      end

    private

      def subscriber_lists_url(attributes = nil)
        if attributes
          tags = attributes["tags"]
          links = attributes["links"]
          document_type = attributes["document_type"]

          params = {}
          params[:tags] = tags if tags
          params[:links] = links if links
          params[:document_type] = document_type if document_type

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
