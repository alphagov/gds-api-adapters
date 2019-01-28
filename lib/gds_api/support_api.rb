require_relative 'base'

# @api documented
class GdsApi::SupportApi < GdsApi::Base
  def create_problem_report(request_details)
    post_json("#{endpoint}/anonymous-feedback/problem-reports", problem_report: request_details)
  end

  def create_service_feedback(request_details)
    post_json("#{endpoint}/anonymous-feedback/service-feedback", service_feedback: request_details)
  end

  def create_anonymous_long_form_contact(request_details)
    post_json("#{endpoint}/anonymous-feedback/long-form-contacts", long_form_contact: request_details)
  end

  def create_feedback_export_request(request_details)
    post_json("#{endpoint}/anonymous-feedback/export-requests", export_request: request_details)
  end

  def create_global_export_request(request_details)
    post_json("#{endpoint}/anonymous-feedback/global-export-requests", global_export_request: request_details)
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
    post_json("#{endpoint}/page-improvements", params)
  end

  def problem_report_daily_totals_for(date)
    date_string = date.strftime("%Y-%m-%d")
    get_json("#{endpoint}/anonymous-feedback/problem-reports/#{date_string}/totals")
  end

  def create_business_finder_feedback(params)
    post_json("#{endpoint}/anonymous-feedback/business-finder", params)
  end

  def anonymous_feedback(options = {})
    uri = "#{endpoint}/anonymous-feedback" + query_string(options)
    get_json(uri)
  end

  def organisation_summary(organisation_slug, options = {})
    uri = "#{endpoint}/anonymous-feedback/organisations/#{organisation_slug}" + query_string(options)
    get_json(uri)
  end

  def organisations_list
    get_json("#{endpoint}/organisations")
  end

  def organisation(organisation_slug)
    get_json("#{endpoint}/organisations/#{organisation_slug}")
  end

  def document_type_list
    get_json("#{endpoint}/anonymous-feedback/document-types")
  end

  def document_type_summary(document_type, options = {})
    uri = "#{endpoint}/anonymous-feedback/document-types/#{document_type}" + query_string(options)
    get_json(uri)
  end

  def feedback_by_day(date, page = 1, per_page = 100)
    uri = "#{endpoint}/feedback-by-day/#{date.strftime('%Y-%m-%d')}?page=#{page}&per_page=#{per_page}"
    get_json(uri)
  end

  def feedback_export_request(id)
    get_json("#{endpoint}/anonymous-feedback/export-requests/#{id}")
  end

  # Fetch a list of problem reports.
  #
  # Makes a +GET+ request.
  #
  # If no options are supplied, the first page of unreviewed feedback is returned.
  #
  # The results are ordered date descending.
  #
  # # ==== Options [+Hash+]
  #
  # * +:from_date+ - from date for list of reports.
  # * +:to_date+ - to date for list of reports.
  # * +:page+ - page number for reports.
  # * +:include_reviewed+ - if true, includes reviewed reports in the list.
  #
  # # @example
  #
  #  support_api.problem_reports({ from_date: '2016-12-12', to_date: '2016-12-13', page: 1, include_reviewed: true }).to_h
  #
  #  #=> {
  #    results: [
  #      {
  #        id: 1,
  #        type: "problem-report",
  #        what_wrong: "Yeti",
  #        what_doing: "Skiing",
  #        url: "http://www.dev.gov.uk/skiing",
  #        referrer: "https://www.gov.uk/browse",
  #        user_agent: "Safari",
  #        path: "/skiing",
  #        marked_as_spam: false,
  #        reviewed: true,
  #        created_at: "2015-01-01T16:00:00.000Z"
  #      },
  #      ...
  #    ]
  #    total_count: 1000,
  #    current_page: 1,
  #    pages: 50,
  #    page_size: 50
  #  }
  def problem_reports(options = {})
    uri = "#{endpoint}/anonymous-feedback/problem-reports" + query_string(options)
    get_json(uri)
  end

  # Update multiple problem reports as reviewed for spam.
  #
  # Makes a +PUT+ request.
  #
  # @param request_details [Hash] Containing keys that match IDs of Problem
  #                               Reports mapped to a boolean value - true if
  #                               that report is to be marked as spam, or false otherwise.
  #
  # # @example
  #
  #  support_api.mark_reviewed_for_spam({ "1" => false, "2" => true }).to_h
  #
  # #=> { "success" => true } (status: 200)
  #
  # # @example
  #
  # Where there is no problem report with ID of 1.
  #
  #  support_api.mark_reviewed_for_spam({ "1" => true }).to_h
  #
  # #=> { "success" =>  false} (status: 400)
  def mark_reviewed_for_spam(request_details)
    put_json("#{endpoint}/anonymous-feedback/problem-reports/mark-reviewed-for-spam", reviewed_problem_report_ids: request_details)
  end
end
