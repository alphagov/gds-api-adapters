require 'gds_api/test_helpers/json_client_helper'
require 'json'

module GdsApi
  module TestHelpers
    module EmailAlertApi
      EMAIL_ALERT_API_ENDPOINT = Plek.find("email-alert-api")

      def stub_email_alert_api_has_updated_subscriber(id, new_address)
        stub_request(:patch, "#{EMAIL_ALERT_API_ENDPOINT}/subscribers/#{id}")
          .to_return(
            status: 200,
            body: get_subscriber_response(id, new_address).to_json,
          )
      end

      def stub_email_alert_api_does_not_have_updated_subscriber(id)
        stub_request(:patch, "#{EMAIL_ALERT_API_ENDPOINT}/subscribers/#{id}")
          .to_return(status: 404)
      end

      def stub_email_alert_api_has_updated_subscription(subscription_id, frequency)
        stub_request(:patch, "#{EMAIL_ALERT_API_ENDPOINT}/subscriptions/#{subscription_id}")
          .to_return(
            status: 200,
            body: get_subscription_response(subscription_id, frequency: frequency).to_json,
          )
      end

      def stub_email_alert_api_does_not_have_updated_subscription(subscription_id)
        stub_request(:patch, "#{EMAIL_ALERT_API_ENDPOINT}/subscriptions/#{subscription_id}")
          .to_return(status: 404)
      end

      def stub_email_alert_api_has_subscriber_subscriptions(id, address)
        stub_request(:get, "#{EMAIL_ALERT_API_ENDPOINT}/subscribers/#{id}/subscriptions")
          .to_return(
            status: 200,
            body: get_subscriber_subscriptions_response(id, address).to_json,
          )
      end

      def stub_email_alert_api_does_not_have_subscriber_subscriptions(id)
        stub_request(:get, "#{EMAIL_ALERT_API_ENDPOINT}/subscribers/#{id}/subscriptions")
          .to_return(status: 404)
      end

      def stub_email_alert_api_has_subscription(
        id,
        frequency,
        title: "Some title",
        subscriber_id: 1,
        subscriber_list_id: 1000,
        ended: false
      )
        response = get_subscription_response(
          id,
          frequency: frequency,
          title: title,
          subscriber_id: subscriber_id,
          subscriber_list_id: subscriber_list_id,
          ended: ended,
        ).to_json

        stub_request(:get, "#{EMAIL_ALERT_API_ENDPOINT}/subscriptions/#{id}")
          .to_return(status: 200, body: response)
        stub_request(:get, "#{EMAIL_ALERT_API_ENDPOINT}/subscriptions/#{id}/latest")
          .to_return(status: 200, body: response)
      end

      def stub_email_alert_api_has_subscriber_list(attributes)
        stub_request(:get, build_subscriber_lists_url(attributes))
          .to_return(
            status: 200,
            body: get_subscriber_list_response(attributes).to_json,
          )
      end

      def stub_email_alert_api_does_not_have_subscriber_list(attributes)
        stub_request(:get, build_subscriber_lists_url(attributes))
          .to_return(status: 404)
      end

      def stub_email_alert_api_creates_subscriber_list(attributes)
        stub_request(:post, build_subscriber_lists_url)
          .to_return(
            status: 201,
            body: get_subscriber_list_response(attributes).to_json,
          )
      end

      def stub_email_alert_api_refuses_to_create_subscriber_list
        stub_request(:post, build_subscriber_lists_url)
          .to_return(status: 422)
      end

      def stub_email_alert_api_accepts_unpublishing_message
        stub_request(:post, "#{EMAIL_ALERT_API_ENDPOINT}/unpublish-messages")
          .to_return(status: 202, body: {}.to_json)
      end

      def stub_email_alert_api_accepts_alert
        stub_request(:post, "#{EMAIL_ALERT_API_ENDPOINT}/notifications")
          .to_return(status: 202, body: {}.to_json)
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

        assert_requested(:post, "#{EMAIL_ALERT_API_ENDPOINT}/notifications", times: 1, &matcher)
      end

      def stub_email_alert_api_has_notifications(notifications, start_at = nil)
        url = "#{EMAIL_ALERT_API_ENDPOINT}/notifications"
        url += "?start_at=#{start_at}" if start_at
        url_regexp = Regexp.new("^#{Regexp.escape(url)}$")

        stub_request(:get, url_regexp)
          .to_return(
            status: 200,
            body: notifications.to_json
          )
      end

      def stub_email_alert_api_has_notification(notification)
        url = "#{EMAIL_ALERT_API_ENDPOINT}/notifications/#{notification['web_service_bulletin']['to_param']}"

        stub_request(:get, url).to_return(
          status: 200,
          body: notification.to_json
        )
      end

      def stub_email_alert_api_unsubscribes_a_subscription(uuid)
        stub_request(:post, "#{EMAIL_ALERT_API_ENDPOINT}/unsubscribe/#{uuid}")
          .with(body: "{}")
          .to_return(status: 204)
      end

      def stub_email_alert_api_has_no_subscription_for_uuid(uuid)
        stub_request(:post, "#{EMAIL_ALERT_API_ENDPOINT}/unsubscribe/#{uuid}")
          .with(body: "{}")
          .to_return(status: 404)
      end

      def stub_email_alert_api_unsubscribes_a_subscriber(subscriber_id)
        stub_request(:delete, "#{EMAIL_ALERT_API_ENDPOINT}/subscribers/#{subscriber_id}")
          .to_return(status: 204)
      end

      def stub_email_alert_api_has_no_subscriber(subscriber_id)
        stub_request(:delete, "#{EMAIL_ALERT_API_ENDPOINT}/subscribers/#{subscriber_id}")
          .to_return(status: 404)
      end

      def stub_email_alert_api_creates_a_subscription(subscriber_list_id, address, frequency, returned_subscription_id)
        stub_request(:post, "#{EMAIL_ALERT_API_ENDPOINT}/subscriptions")
          .with(
            body: { subscriber_list_id: subscriber_list_id, address: address, frequency: frequency }.to_json
        ).to_return(status: 201, body: { subscription_id: returned_subscription_id }.to_json)
      end

      def stub_email_alert_api_creates_an_existing_subscription(subscriber_list_id, address, frequency, returned_subscription_id)
        stub_request(:post, "#{EMAIL_ALERT_API_ENDPOINT}/subscriptions")
          .with(
            body: { subscriber_list_id: subscriber_list_id, address: address, frequency: frequency }.to_json
        ).to_return(status: 200, body: { subscription_id: returned_subscription_id }.to_json)
      end

      def stub_email_alert_api_refuses_to_create_subscription(subscriber_list_id, address, frequency)
        stub_request(:post, "#{EMAIL_ALERT_API_ENDPOINT}/subscriptions")
          .with(
            body: { subscriber_list_id: subscriber_list_id, address: address, frequency: frequency }.to_json
        ).to_return(status: 422)
      end

      def stub_email_alert_api_creates_an_auth_token(subscriber_id, address)
        stub_request(:post, "#{EMAIL_ALERT_API_ENDPOINT}/subscribers/auth-token")
          .to_return(
            status: 201,
            body: get_subscriber_response(subscriber_id, address).to_json
          )
      end

      def assert_unsubscribed(uuid)
        assert_requested(:post, "#{EMAIL_ALERT_API_ENDPOINT}/unsubscribe/#{uuid}", times: 1)
      end

      def assert_subscribed(subscriber_list_id, address, frequency = "immediately")
        assert_requested(:post, "#{EMAIL_ALERT_API_ENDPOINT}/subscriptions") do |req|
          JSON.parse(req.body).symbolize_keys == {
            subscriber_list_id: subscriber_list_id,
            address: address,
            frequency: frequency
          }
        end
      end

      def stub_email_alert_api_has_subscriber_list_by_slug(slug:, returned_attributes:)
        stub_request(:get, "#{EMAIL_ALERT_API_ENDPOINT}/subscriber-lists/#{slug}")
          .to_return(
            status: 200,
            body: {
              subscriber_list: returned_attributes
            }.to_json
        )
      end

      def stub_email_alert_api_does_not_have_subscriber_list_by_slug(slug:)
        stub_request(:get, "#{EMAIL_ALERT_API_ENDPOINT}/subscriber-lists/#{slug}")
          .to_return(status: 404)
      end

      # Aliases for DEPRECATED methods
      alias_method :email_alert_api_has_updated_subscriber, :stub_email_alert_api_has_updated_subscriber
      alias_method :email_alert_api_does_not_have_updated_subscriber, :stub_email_alert_api_does_not_have_updated_subscriber
      alias_method :email_alert_api_has_updated_subscription, :stub_email_alert_api_has_updated_subscription
      alias_method :email_alert_api_does_not_have_updated_subscription, :stub_email_alert_api_does_not_have_updated_subscription
      alias_method :email_alert_api_has_subscriber_subscriptions, :stub_email_alert_api_has_subscriber_subscriptions
      alias_method :email_alert_api_does_not_have_subscriber_subscriptions, :stub_email_alert_api_does_not_have_subscriber_subscriptions
      alias_method :email_alert_api_has_subscription, :stub_email_alert_api_has_subscription
      alias_method :email_alert_api_has_subscriber_list, :stub_email_alert_api_has_subscriber_list
      alias_method :email_alert_api_does_not_have_subscriber_list, :stub_email_alert_api_does_not_have_subscriber_list
      alias_method :email_alert_api_creates_subscriber_list, :stub_email_alert_api_creates_subscriber_list
      alias_method :email_alert_api_refuses_to_create_subscriber_list, :stub_email_alert_api_refuses_to_create_subscriber_list
      alias_method :email_alert_api_accepts_unpublishing_message, :stub_email_alert_api_accepts_unpublishing_message
      alias_method :email_alert_api_accepts_alert, :stub_email_alert_api_accepts_alert
      alias_method :email_alert_api_has_notifications, :stub_email_alert_api_has_notifications
      alias_method :email_alert_api_has_notification, :stub_email_alert_api_has_notification
      alias_method :email_alert_api_unsubscribes_a_subscription, :stub_email_alert_api_unsubscribes_a_subscription
      alias_method :email_alert_api_has_no_subscription_for_uuid, :stub_email_alert_api_has_no_subscription_for_uuid
      alias_method :email_alert_api_unsubscribes_a_subscriber, :stub_email_alert_api_unsubscribes_a_subscriber
      alias_method :email_alert_api_has_no_subscriber, :stub_email_alert_api_has_no_subscriber
      alias_method :email_alert_api_creates_a_subscription, :stub_email_alert_api_creates_a_subscription
      alias_method :email_alert_api_creates_an_existing_subscription, :stub_email_alert_api_creates_an_existing_subscription
      alias_method :email_alert_api_refuses_to_create_subscription, :stub_email_alert_api_refuses_to_create_subscription
      alias_method :email_alert_api_creates_an_auth_token, :stub_email_alert_api_creates_an_auth_token
      alias_method :email_alert_api_has_subscriber_list_by_slug, :stub_email_alert_api_has_subscriber_list_by_slug
      alias_method :email_alert_api_does_not_have_subscriber_list_by_slug, :stub_email_alert_api_does_not_have_subscriber_list_by_slug

    private

      def get_subscriber_response(id, address)
        {
          "subscriber" => {
            "id" => id,
            "address" => address
          }
        }
      end

      def get_subscription_response(
        id,
        frequency: "daily",
        title: "Some title",
        subscriber_id: 1,
        subscriber_list_id: 1000,
        ended: false
      )
        {
          "subscription" => {
            "id" => id,
            "frequency" => frequency,
            "source" => "user_signed_up",
            "ended_at" => ended ? Time.now.to_datetime.rfc3339 : nil,
            "ended_reason" => ended ? "unsubscribed" : nil,
            "subscriber" => {
              "id" => subscriber_id,
              "address" => "test@example.com",
            },
            "subscriber_list" => {
              "id" => subscriber_list_id,
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
            "active_subscriptions_count" => 42,
          }.merge(attributes)
        }
      end

      def post_alert_response
        {}
      end

      def build_subscriber_lists_url(attributes = nil)
        if attributes
          tags = attributes["tags"]
          links = attributes["links"]
          document_type = attributes["document_type"]
          email_document_supertype = attributes["email_document_supertype"]
          government_document_supertype = attributes["government_document_supertype"]
          gov_delivery_id = attributes["gov_delivery_id"]
          content_purpose_supergroup = attributes["content_purpose_supergroup"]

          params = {}
          params[:tags] = tags if tags
          params[:links] = links if links
          params[:document_type] = document_type if document_type
          params[:email_document_supertype] = email_document_supertype if email_document_supertype
          params[:government_document_supertype] = government_document_supertype if government_document_supertype
          params[:gov_delivery_id] = gov_delivery_id if gov_delivery_id
          params[:content_purpose_supergroup] = content_purpose_supergroup if content_purpose_supergroup

          query = Rack::Utils.build_nested_query(params)
        end

        url = "#{EMAIL_ALERT_API_ENDPOINT}/subscriber-lists"
        query ? "#{url}?#{query}" : url
      end
    end
  end
end
