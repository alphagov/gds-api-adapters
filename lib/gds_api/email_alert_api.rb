require_relative 'base'
require_relative 'exceptions'

class GdsApi::EmailAlertApi < GdsApi::Base

  def find_or_create_subscriber_list(attributes)
    search_subscriber_list_by_tags(attributes.fetch("tags"))
  rescue GdsApi::HTTPNotFound
    create_subscriber_list(attributes)
  end

  def send_alert(publication)
    post_json!("#{endpoint}/notifications", publication)
  end

private

  def search_subscriber_list_by_tags(tags)
    get_json!("#{endpoint}/subscriber_lists?" + nested_query_string(tags: tags))
  end

  def create_subscriber_list(attributes)
    post_json!("#{endpoint}/subscriber_lists", attributes)
  end

  def nested_query_string(params)
    Rack::Utils.build_nested_query(params)
  end
end
