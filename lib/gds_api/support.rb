require_relative 'base'

class GdsApi::Support < GdsApi::Base
  def create_foi_request(request_details)
    post_json("#{base_url}/foi_requests", { :foi_request => request_details })
  end

  def create_problem_report(request_details)
    post_json("#{base_url}/problem_reports", { :problem_report => request_details })
  end

  private
  def base_url
    endpoint
  end
end
