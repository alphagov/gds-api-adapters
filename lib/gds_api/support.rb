require_relative "base"

class GdsApi::Support < GdsApi::Base
  def create_foi_request(request_details)
    post_json("#{base_url}/foi_requests", foi_request: request_details)
  end

  def create_named_contact(request_details)
    post_json("#{base_url}/named_contacts", named_contact: request_details)
  end

  def feedback_url(slug)
    "#{base_url}/anonymous_feedback?path=#{slug}"
  end

private

  def base_url
    endpoint
  end
end
