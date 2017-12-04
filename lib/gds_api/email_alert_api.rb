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

    query_string = nested_query_string(params)
    get_json("#{endpoint}/subscriber-lists?" + query_string)
  end

  # Post a subscriber list
  #
  # @param attributes [Hash] document_type, links, tags used to search existing subscriber lists
  def create_subscriber_list(attributes)
    post_json("#{endpoint}/subscriber-lists", attributes)
  end

  # Post notification
  #
  # @param publication [Hash] Valid publication attributes
  def send_alert(publication, headers = {})
    post_json("#{endpoint}/notifications", publication, headers)
  end

  # Get notifications
  #
  # @option start_at [String] Optional GovDelivery bulletin id to page back through notifications
  #
  # @return [Hash] notifications
  def notifications(start_at = nil)
    url = "#{endpoint}/notifications"
    url += "?start_at=#{start_at}" if start_at
    get_json(url)
  end

  # Get notification
  #
  # @param id [String] GovDelivery bulletin id
  #
  # @return [Hash] notification
  def notification(id)
    get_json("#{endpoint}/notifications/#{id}")
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

  # Unsubscribe
  # #
  # @param uuid Subscription uuid
  #
  # @return [Hash] deleted
  def unsubscribe(uuid)
    post_json("#{endpoint}/unsubscribe/#{uuid}")
  end

  # Subscribe
  #
  # @return [Hash] subscription_id
  def subscribe(subscribable_id:, address:)
    post_json(
      "#{endpoint}/subscriptions",
      subscribable_id: subscribable_id,
      address: address,
    )
  end

private

  def nested_query_string(params)
    Rack::Utils.build_nested_query(params)
  end
end
