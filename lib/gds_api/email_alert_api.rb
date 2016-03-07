require_relative 'base'
require_relative 'exceptions'

class GdsApi::EmailAlertApi < GdsApi::Base

  def find_or_create_subscriber_list(attributes)
    tags = attributes["tags"]
    links = attributes["links"]
    document_type = attributes["document_type"]

    if tags && links
      message = "please provide either tags or links (or neither), but not both"
      raise ArgumentError, message
    end

    params = {}
    params[:tags] = tags if tags
    params[:links] = links if links
    params[:document_type] = document_type if document_type

    search_subscriber_list(params)
  rescue GdsApi::HTTPNotFound
    create_subscriber_list(attributes)
  end

  def send_alert(publication)
    post_json!("#{endpoint}/notifications", publication)
  end

private

  def search_subscriber_list(params)
    query_string = nested_query_string(params)
    get_json!("#{endpoint}/subscriber-lists?" + query_string)
  end

  def create_subscriber_list(attributes)
    post_json!("#{endpoint}/subscriber-lists", attributes)
  end

  def nested_query_string(params)
    Rack::Utils.build_nested_query(params)
  end
end
