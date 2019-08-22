require_relative 'base'
require_relative 'exceptions'

# Adapter for the Email Alert API
#
# @see https://github.com/alphagov/email-alert-api
# @api documented
class GdsApi::EmailAlertApi < GdsApi::Base
  # Get or Post subscriber list
  #
  # @param attributes [Hash] document_type, links, tags used to search existing subscriber lists
  def find_or_create_subscriber_list(attributes)
    find_subscriber_list(attributes)
  rescue GdsApi::HTTPNotFound
    create_subscriber_list(attributes)
  end

  # Get a subscriber list
  #
  # @param attributes [Hash] document_type, links, tags used to search existing subscriber lists
  def find_subscriber_list(attributes)
    tags = attributes["tags"]
    links = attributes["links"]
    document_type = attributes["document_type"]
    email_document_supertype = attributes["email_document_supertype"]
    government_document_supertype = attributes["government_document_supertype"]
    gov_delivery_id = attributes["gov_delivery_id"]
    combine_mode = attributes["combine_mode"]

    if tags && links
      message = "please provide either tags or links (or neither), but not both"
      raise ArgumentError, message
    end

    params = {}
    params[:tags] = tags if tags
    params[:links] = links if links
    params[:document_type] = document_type if document_type
    params[:email_document_supertype] = email_document_supertype if email_document_supertype
    params[:government_document_supertype] = government_document_supertype if government_document_supertype
    params[:gov_delivery_id] = gov_delivery_id if gov_delivery_id
    params[:combine_mode] = combine_mode if combine_mode

    query_string = nested_query_string(params)
    get_json("#{endpoint}/subscriber-lists?" + query_string)
  end

  # Post a subscriber list
  #
  # @param attributes [Hash] document_type, links, tags used to search existing subscriber lists
  def create_subscriber_list(attributes)
    post_json("#{endpoint}/subscriber-lists", attributes)
  end

  # Post a content change
  #
  # @param content_change [Hash] Valid content change attributes
  def create_content_change(content_change, headers = {})
    post_json("#{endpoint}/content-changes", content_change, headers)
  end

  # Send email
  #
  # @param email_params [Hash] address, subject, body
  def send_email(email_params)
    post_json("#{endpoint}/emails", email_params)
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
    post_json("#{endpoint}/unsubscribe/#{uuid}")
  end

  # Unsubscribe subscriber from everything
  #
  # @param [integer] Subscriber id
  #
  # @return [nil]
  def unsubscribe_subscriber(id)
    delete_json("#{endpoint}/subscribers/#{id}")
  end

  # Subscribe
  #
  # @return [Hash] subscription_id
  def subscribe(subscriber_list_id:, address:, frequency: "immediately")
    post_json(
      "#{endpoint}/subscriptions",
      subscriber_list_id: subscriber_list_id,
      address: address,
      frequency: frequency,
    )
  end

  # Get a Subscriber List
  #
  # @return [Hash] subscriber_list: {
  #  id
  #  title
  #  gov_delivery_id
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
    get_json("#{endpoint}/subscriber-lists/#{slug}")
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
    get_json("#{endpoint}/subscriptions/#{id}")
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
    get_json("#{endpoint}/subscriptions/#{id}/latest")
  end

  # Get Subscriptions for a Subscriber
  #
  # @param [integer] Subscriber id
  #
  # @return [Hash] subscriber, subscriptions
  def get_subscriptions(id:)
    get_json("#{endpoint}/subscribers/#{id}/subscriptions")
  end

  # Patch a Subscriber
  #
  # @param [integer] Subscriber id
  # @param [string] Subscriber new_address
  #
  # @return [Hash] subscriber
  def change_subscriber(id:, new_address:)
    patch_json(
      "#{endpoint}/subscribers/#{id}",
      new_address: new_address
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
      "#{endpoint}/subscriptions/#{id}",
      frequency: frequency
    )
  end

  # Create an authentication token for a subscriber
  #
  # @param [string]       address       Email address of subscriber to create token for
  # @param [string]       destination   Path on GOV.UK that subscriber will be emailed
  # @param [string, nil]  redirect      Path on GOV.UK to be encoded into the token for redirecting
  #
  # @return [Hash]  subscriber
  #
  def create_auth_token(address:, destination:, redirect: nil)
    post_json(
      "#{endpoint}/subscribers/auth-token",
      address: address,
      destination: destination,
      redirect: redirect,
    )
  end

private

  def nested_query_string(params)
    Rack::Utils.build_nested_query(params)
  end
end
