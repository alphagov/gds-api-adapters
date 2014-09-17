require_relative 'base'

class GdsApi::SupportApi < GdsApi::Base
  def create_service_feedback(request_details)
    post_json!("#{endpoint}/anonymous-feedback/service-feedback", { :service_feedback => request_details })
  end

  def create_anonymous_long_form_contact(request_details)
    post_json!("#{endpoint}/anonymous-feedback/long-form-contacts", { :long_form_contact => request_details })
  end
end
