require_relative 'base'

class GdsApi::Support < GdsApi::Base
  def create_foi_request(request_details, options = {})
    post_json!("#{base_url}/foi_requests", { :foi_request => request_details }, options[:headers] || {})
  end

  def create_problem_report(request_details, options = {})
    post_json!("#{base_url}/anonymous_feedback/problem_reports", { :problem_report => request_details }, options[:headers] || {})
  end

  private
  def base_url
    endpoint
  end
end
