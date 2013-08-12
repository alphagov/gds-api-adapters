require_relative 'base'

class GdsApi::Support < GdsApi::Base
  def create_foi_request(request_details)
    post_json("#{base_url}/foi_requests", { :foi_request => request_details })
  end

  private
  def base_url
    endpoint
  end
end
