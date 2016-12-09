require_relative 'base'

class GdsApi::Support < GdsApi::Base
  def create_foi_request(request_details)
    post_json!("#{base_url}/foi_requests", foi_request: request_details)
  end

  def create_problem_report(request_details)
    post_json!("#{base_url}/anonymous_feedback/problem_reports", problem_report: request_details)
  end

  def create_named_contact(request_details)
    post_json!("#{base_url}/named_contacts", named_contact: request_details)
  end

  def create_anonymous_long_form_contact(request_details)
    post_json!("#{base_url}/anonymous_feedback/long_form_contacts", long_form_contact: request_details)
  end

  def create_service_feedback(request_details)
    post_json!("#{base_url}/anonymous_feedback/service_feedback", service_feedback: request_details)
  end

  def feedback_url(slug)
    "#{base_url}/anonymous_feedback?path=#{slug}"
  end

private

  def base_url
    endpoint
  end
end
