require_relative 'base'

class GdsApi::SupportApi < GdsApi::Base
  def create_service_feedback(request_details)
    post_json!("#{endpoint}/anonymous-feedback/service-feedback", { :service_feedback => request_details })
  end
end
