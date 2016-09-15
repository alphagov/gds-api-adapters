require_relative 'base'

class GdsApi::SupportApi < GdsApi::Base
  def create_problem_report(request_details)
    post_json!("#{endpoint}/anonymous-feedback/problem-reports", { :problem_report => request_details })
  end

  def create_service_feedback(request_details)
    post_json!("#{endpoint}/anonymous-feedback/service-feedback", { :service_feedback => request_details })
  end

  def create_anonymous_long_form_contact(request_details)
    post_json!("#{endpoint}/anonymous-feedback/long-form-contacts", { :long_form_contact => request_details })
  end

  def create_feedback_export_request(request_details)
    post_json!("#{endpoint}/anonymous-feedback/export-requests", export_request: request_details)
  end

  def create_global_export_request(request_details)
    post_json!("#{endpoint}/anonymous-feedback/global-export-requests", global_export_request: request_details)
  end

  # Create a Page Improvement
  #
  # Makes a +POST+ request to the support api to create a Page Improvement.
  #
  # @param params [Hash] Any attributes that relate to a Page Improvement.
  #
  # @return [GdsApi::Response] The wrapped http response from the api. Responds to the following:
  #     :status       a string that is either 'success' or 'error'
  #
  # @raise [HTTPErrorResponse] if the request returns an error
  #
  # @example
  #   support_api.create_page_improvement(
  #     description: 'The title is wrong',
  #     path: 'http://gov.uk/service-manual/agile'
  # )
  def create_page_improvement(params)
    post_json!("#{endpoint}/page-improvements", params)
  end

  def problem_report_daily_totals_for(date)
    date_string = date.strftime("%Y-%m-%d")
    get_json!("#{endpoint}/anonymous-feedback/problem-reports/#{date_string}/totals")
  end

  def anonymous_feedback(options = {})
    uri = "#{endpoint}/anonymous-feedback" + query_string(options)
    get_json!(uri)
  end

  def organisation_summary(organisation_slug, options = {})
    uri = "#{endpoint}/anonymous-feedback/organisations/#{organisation_slug}" + query_string(options)
    get_json!(uri)
  end

  def organisations_list
    get_json!("#{endpoint}/organisations")
  end

  def organisation(organisation_slug)
    get_json!("#{endpoint}/organisations/#{organisation_slug}")
  end

  def feedback_export_request(id)
    get_json!("#{endpoint}/anonymous-feedback/export-requests/#{id}")
  end
end
