require 'json'

module GdsApi
  module TestHelpers
    module GovUkDelivery

      GOVUK_DELIVERY_ENDPOINT = Plek.current.find('govuk-delivery')

      def govuk_delivery_create_topic_success(feed_url, title, description=nil)
        stub_request(:post, "#{GOVUK_DELIVERY_ENDPOINT}/lists").
          with(body: {feed_url: feed_url, title: title, description: description}.to_json).
          to_return(body: '', status: 201)
      end

      def govuk_delivery_create_topic_invalid_params(feed_url, title, description=nil)
        stub_request(:post, "#{GOVUK_DELIVERY_ENDPOINT}/lists").
          with(body: {feed_url: feed_url, description: description}.to_json).
          to_return(body: '', status: 400)
      end

      def govuk_delivery_create_topic_error(feed_url, title, description=nil)
        stub_request(:post, "#{GOVUK_DELIVERY_ENDPOINT}/lists").
          with(body: {feed_url: feed_url, title: title, description: description}.to_json).
          to_return(body: '', status: 500)
      end

      def govuk_delivery_create_notification_success(feed_urls, subject, body)
        stub_request(:post, "#{GOVUK_DELIVERY_ENDPOINT}/notifications")
          .with(body: {feed_urls: feed_urls, subject: subject, body: body}.to_json)
          .to_return(body: '', status: 201)
      end

      def govuk_delivery_create_notification_invalid_params(feed_urls, subject, body)
        stub_request(:post, "#{GOVUK_DELIVERY_ENDPOINT}/notifications")
          .with(body: {subject: subject, body: body}.to_json)
          .to_return(body: '', status: 400)
      end

      def govuk_delivery_create_notification_error(feed_urls, subject, body)
        stub_request(:post, "#{GOVUK_DELIVERY_ENDPOINT}/notifications")
          .with(body: {feed_urls: feed_urls, subject: subject, body: body}.to_json)
          .to_return(body: '', status: 500)
      end


      def govuk_delivery_create_subscriber_success(email, feed_urls)
        stub_request(:post, "#{GOVUK_DELIVERY_ENDPOINT}/subscriptions")
          .with(body: {email: email, feed_urls: feed_urls}.to_json)
          .to_return(body: '', status: 201)
      end

      def govuk_delivery_create_subscriber_invalid_params(email, feed_urls)
        stub_request(:post, "#{GOVUK_DELIVERY_ENDPOINT}/subscriptions")
          .with(body: {feed_urls: feed_urls}.to_json)
          .to_return(body: '', status: 400)
      end

      def govuk_delivery_create_subscriber_error(email, feed_urls)
        stub_request(:post, "#{GOVUK_DELIVERY_ENDPOINT}/subscriptions")
          .with(body: {email: email, feed_urls: feed_urls}.to_json)
          .to_return(body: '', status: 500)
      end
    end
  end
end
