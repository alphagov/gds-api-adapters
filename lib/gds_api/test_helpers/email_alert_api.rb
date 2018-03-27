require 'gds_api/test_helpers/json_client_helper'
require 'json'

module GdsApi
  module TestHelpers
    module EmailAlertApi
      EMAIL_ALERT_API_ENDPOINT = Plek.find("email-alert-api")

      def email_alert_api_has_updated_subscriber(id, new_address)
        stub_request(:patch, subscriber_url(id))
          .to_return(
            status: 200,
            body: get_subscriber_response(id, new_address).to_json,
          )
      end

      def email_alert_api_does_not_have_updated_subscriber(id)
        stub_request(:patch, subscriber_url(id))
          .to_return(status: 404)
      end

      def email_alert_api_has_updated_subscription(subscription_id, frequency)
        stub_request(:patch, subscription_url(subscription_id))
          .to_return(
            status: 200,
            body: get_subscription_response(subscription_id, frequency).to_json,
          )
      end

      def email_alert_api_does_not_have_updated_subscription(subscription_id)
        stub_request(:patch, subscription_url(subscription_id))
          .to_return(status: 404)
      end

      def email_alert_api_has_subscriber_subscriptions(id, address)
        stub_request(:get, subscriber_subscriptions_url(id))
          .to_return(
            status: 200,
            body: get_subscriber_subscriptions_response(id, address).to_json,
          )
      end

      def email_alert_api_does_not_have_subscriber_subscriptions(id)
        stub_request(:get, subscriber_subscriptions_url(id))
          .to_return(status: 404)
      end

      def email_alert_api_has_subscription(id, frequency, title: "Some title")
        stub_request(:get, subscription_url(id))
          .to_return(
            status: 200,
            body: get_subscription_response(id, frequency, title).to_json,
          )
      end

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

      def get_subscriber_response(id, address)
        {
          "subscriber" => {
            "id" => id,
            "address" => address
          }
        }
      end

      def get_subscription_response(id, frequency, title = "Some title")
        {
          "subscription" => {
            "subscriber_id" => 1,
            "subscriber_list_id" => 1000,
            "frequency" => frequency,
            "id" => id,
            "subscriber_list" => {
              "id" => 1000,
              "slug" => "some-thing",
              "title" => title,
            }
          }
        }
      end

      def get_subscriber_subscriptions_response(id, address)
        {
          "subscriber" => {
            "id" => id,
            "address" => address
          },
          "subscriptions" => [
            {
              "subscriber_id" => 1,
              "subscriber_list_id" => 1000,
              "frequency" => "daily",
              "id" => "447135c3-07d6-4c3a-8a3b-efa49ef70e52",
              "subscriber_list" => {
                "id" => 1000,
                "slug" => "some-thing"
              }
            }
          ]
        }
      end

      def get_subscriber_list_response(attributes)
        {
          "subscriber_list" => {
            "id" => "447135c3-07d6-4c3a-8a3b-efa49ef70e52",
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

      def email_alert_api_unsubscribes_a_subscription(uuid)
        stub_request(:post, unsubscribe_url(uuid))
          .with(body: "{}")
          .to_return(status: 204)
      end

      def email_alert_api_has_no_subscription_for_uuid(uuid)
        stub_request(:post, unsubscribe_url(uuid))
          .with(body: "{}")
          .to_return(status: 404)
      end

      def email_alert_api_unsubscribes_a_subscriber(subscriber_id)
        stub_request(:delete, unsubscribe_subscriber_url(subscriber_id))
          .to_return(status: 204)
      end

      def email_alert_api_has_no_subscriber(subscriber_id)
        stub_request(:delete, unsubscribe_subscriber_url(subscriber_id))
          .to_return(status: 404)
      end

      def email_alert_api_creates_a_subscription(subscribable_id, address, frequency, returned_subscription_id)
        stub_request(:post, subscribe_url)
          .with(
            body: { subscribable_id: subscribable_id, address: address, frequency: frequency }.to_json
        ).to_return(status: 201, body: { subscription_id: returned_subscription_id }.to_json)
      end

      def email_alert_api_creates_an_existing_subscription(subscribable_id, address, frequency, returned_subscription_id)
        stub_request(:post, subscribe_url)
          .with(
            body: { subscribable_id: subscribable_id, address: address, frequency: frequency }.to_json
        ).to_return(status: 200, body: { subscription_id: returned_subscription_id }.to_json)
      end

      def email_alert_api_refuses_to_create_subscription(subscribable_id, address, frequency)
        stub_request(:post, subscribe_url)
          .with(
            body: { subscribable_id: subscribable_id, address: address, frequency: frequency }.to_json
        ).to_return(status: 422)
      end

      def email_alert_api_creates_an_auth_token(subscriber_id, address)
        stub_request(:post, auth_token_url)
          .to_return(
            status: 201,
            body: get_subscriber_response(subscriber_id, address).to_json
          )
      end

      def assert_unsubscribed(uuid)
        assert_requested(:post, unsubscribe_url(uuid), times: 1)
      end

      def assert_subscribed(subscribable_id, address, frequency = "immediately")
        assert_requested(:post, subscribe_url) do |req|
          JSON.parse(req.body).symbolize_keys == {
            subscribable_id: subscribable_id,
            address: address,
            frequency: frequency
          }
        end
      end

      def email_alert_api_has_subscribable(reference:, returned_attributes:)
        stub_request(:get, subscribable_url(reference))
          .to_return(
            status: 200,
            body: {
              subscribable: returned_attributes
            }.to_json
        )
      end

      def email_alert_api_does_not_have_subscribable(reference:)
        stub_request(:get, subscribable_url(reference))
          .to_return(status: 404)
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

      def unsubscribe_url(uuid)
        EMAIL_ALERT_API_ENDPOINT + "/unsubscribe/#{uuid}"
      end

      def unsubscribe_subscriber_url(id)
        EMAIL_ALERT_API_ENDPOINT + "/subscribers/#{id}"
      end

      def subscribe_url
        EMAIL_ALERT_API_ENDPOINT + "/subscriptions"
      end

      def subscription_url(id)
        EMAIL_ALERT_API_ENDPOINT + "/subscriptions/#{id}"
      end

      def subscribable_url(reference)
        EMAIL_ALERT_API_ENDPOINT + "/subscribables/#{reference}"
      end

      def subscriber_url(id)
        EMAIL_ALERT_API_ENDPOINT + "/subscribers/#{id}"
      end

      def subscriber_subscriptions_url(id)
        EMAIL_ALERT_API_ENDPOINT + "/subscribers/#{id}/subscriptions"
      end

      def auth_token_url
        EMAIL_ALERT_API_ENDPOINT + "/subscribers/auth-token"
      end
    end
  end
end
