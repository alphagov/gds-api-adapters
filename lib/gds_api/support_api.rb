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

  def problem_report_daily_totals_for(date)
    date_string = date.strftime("%Y-%m-%d")
    get_json!("#{endpoint}/anonymous-feedback/problem-reports/#{date_string}/totals")
  end
end
