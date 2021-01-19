require_relative "base"
require_relative "exceptions"

# Adapter for the Email Alert API
#
# @see https://github.com/alphagov/email-alert-api
# @api documented
class GdsApi::EmailAlertApi < GdsApi::Base
  # Get or Post subscriber list
  #
  # @param attributes [Hash] document_type, links, tags used to search existing subscriber lists
  def find_or_create_subscriber_list(attributes)
    if attributes["tags"] && attributes["links"]
      message = "please provide either tags or links (or neither), but not both"
      raise ArgumentError, message
    end

    post_json("#{endpoint}/subscriber-lists", attributes)
  end

  # Post a content change
  #
  # @param content_change [Hash] Valid content change attributes
  def create_content_change(content_change, headers = {})
    post_json("#{endpoint}/content-changes", content_change, headers)
  end

  # Post a message
  #
  # @param message [Hash] Valid message attributes
  def create_message(message, headers = {})
    post_json("#{endpoint}/messages", message, headers)
  end

  # Unpublishing alert
  #
  # @param message [Hash] content_id
  #
  # Used by email-alert-service to send a message to email-alert-api
  # when an unpublishing message is put on the Rabbitmq queue by
  # publishing-api
  def send_unpublish_message(message)
    post_json("#{endpoint}/unpublish-messages", message)
  end

  # Get topic matches
  #
  # @param attributes [Hash] tags, links, document_type,
  # email_document_supertype, government_document_supertype
  #
  # @return [Hash] topics, enabled, disabled
  def topic_matches(attributes)
    query_string = nested_query_string(attributes)
    get_json("#{endpoint}/topic-matches.json?#{query_string}")
  end

  # Unsubscribe subscriber from subscription
  #
  # @param [string] Subscription uuid
  #
  # @return [nil]
  def unsubscribe(uuid)
    post_json("#{endpoint}/unsubscribe/#{uri_encode(uuid)}")
  end

  # Unsubscribe subscriber from everything
  #
  # @param [integer] Subscriber id
  #
  # @return [nil]
  def unsubscribe_subscriber(id)
    delete_json("#{endpoint}/subscribers/#{uri_encode(id)}")
  end

  # Subscribe
  #
  # @return [Hash] subscription_id
  def subscribe(subscriber_list_id:, address:, frequency: "immediately", skip_confirmation_email: false)
    post_json(
      "#{endpoint}/subscriptions",
      subscriber_list_id: subscriber_list_id,
      address: address,
      frequency: frequency,
      skip_confirmation_email: skip_confirmation_email,
    )
  end

  # Get a Subscriber List
  #
  # @return [Hash] subscriber_list: {
  #  id
  #  title
  #  created_at
  #  updated_at
  #  document_type
  #  tags
  #  links
  #  email_document_supertype
  #  government_document_supertype
  #  subscriber_count
  # }
  def get_subscriber_list(slug:)
    get_json("#{endpoint}/subscriber-lists/#{uri_encode(slug)}")
  end

  # Get a Subscription
  #
  # @return [Hash] subscription: {
  #  id
  #  subscriber_list
  #  subscriber
  #  created_at
  #  updated_at
  #  ended_at
  #  ended_reason
  #  frequency
  #  source
  # }
  def get_subscription(id)
    get_json("#{endpoint}/subscriptions/#{uri_encode(id)}")
  end

  # Get the latest Subscription that has the same subscriber_list
  # and email as the Subscription associated with the `id` passed.
  # This may or may not be the same Subscription.
  #
  # @return [Hash] subscription: {
  #  id
  #  subscriber_list
  #  subscriber
  #  created_at
  #  updated_at
  #  ended_at
  #  ended_reason
  #  frequency
  #  source
  # }
  def get_latest_matching_subscription(id)
    get_json("#{endpoint}/subscriptions/#{uri_encode(id)}/latest")
  end

  # Get Subscriptions for a Subscriber
  #
  # @param [integer] Subscriber id
  # @param [string] Subscription order - title, created_at
  #
  # @return [Hash] subscriber, subscriptions
  def get_subscriptions(id:, order: nil)
    if order
      get_json("#{endpoint}/subscribers/#{uri_encode(id)}/subscriptions?order=#{uri_encode(order)}")
    else
      get_json("#{endpoint}/subscribers/#{uri_encode(id)}/subscriptions")
    end
  end

  # Patch a Subscriber
  #
  # @param [integer] Subscriber id
  # @param [string] Subscriber new_address
  #
  # @return [Hash] subscriber
  def change_subscriber(id:, new_address:)
    patch_json(
      "#{endpoint}/subscribers/#{uri_encode(id)}",
      new_address: new_address,
    )
  end

  # Patch a Subscription
  #
  # @param [string] Subscription id
  # @param [string] Subscription frequency
  #
  # @return [Hash] subscription
  def change_subscription(id:, frequency:)
    patch_json(
      "#{endpoint}/subscriptions/#{uri_encode(id)}",
      frequency: frequency,
    )
  end

  # Verify a subscriber has control of a provided email
  #
  # @param [string]       address       Address to send verification email to
  # @param [string]       destination   Path on GOV.UK that subscriber will be emailed
  #
  # @return [Hash]  subscriber
  #
  def send_subscriber_verification_email(address:, destination:)
    post_json(
      "#{endpoint}/subscribers/auth-token",
      address: address,
      destination: destination,
    )
  end

  # Verify a subscriber intends to be added to a subscription
  #
  # @param [string]       address       Address to send verification email to
  # @param [string]       frequency     How often the subscriber wishes to be notified of new items
  # @param [string]       topic_id      The slugs/ID for the topic being subscribed to
  #
  # return [Hash]  subscription
  #
  def send_subscription_verification_email(address:, frequency:, topic_id:)
    post_json(
      "#{endpoint}/subscriptions/auth-token",
      address: address,
      frequency: frequency,
      topic_id: topic_id,
    )
  end

private

  def nested_query_string(params)
    Rack::Utils.build_nested_query(params)
  end
end
