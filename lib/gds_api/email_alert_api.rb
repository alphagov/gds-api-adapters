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

    search_subscriber_list(params)
  rescue GdsApi::HTTPNotFound
    create_subscriber_list(attributes)
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

private

  def search_subscriber_list(params)
    query_string = nested_query_string(params)
    get_json("#{endpoint}/subscriber-lists?" + query_string)
  end

  def create_subscriber_list(attributes)
    post_json("#{endpoint}/subscriber-lists", attributes)
  end

  def nested_query_string(params)
    Rack::Utils.build_nested_query(params)
  end
end
