require "test_helper"
require "gds_api/support_api"
require "gds_api/test_helpers/support_api"

describe GdsApi::SupportApi do
  include GdsApi::TestHelpers::SupportApi

  before do
    @base_api_url = Plek.current.find("support-api")
    @api = GdsApi::SupportApi.new(@base_api_url)
  end

  it "can report a problem" do
    request_details = { certain: "details" }

    stub_post = stub_support_api_problem_report_creation(request_details)

    @api.create_problem_report(request_details)

    assert_requested(stub_post)
  end

  it "can pass service feedback" do
    request_details = { "transaction-completed-values" => "1", "details" => "abc" }

    stub_post = stub_support_api_service_feedback_creation(request_details)

    @api.create_service_feedback(request_details)

    assert_requested(stub_post)
  end

  it "can submit long-form anonymous feedback" do
    request_details = { certain: "details" }

    stub_post = stub_support_api_long_form_anonymous_contact_creation(request_details)

    @api.create_anonymous_long_form_contact(request_details)

    assert_requested(stub_post)
  end

  it "can submit anonymous-contact/business-finder" do
    request_details = { description: "something is missing" }
    stub_post = stub_support_api_create_content_improvement_feedback(request_details)

    @api.create_content_improvement_feedback(request_details)

    assert_requested(stub_post)
  end

  it "fetches problem report daily totals" do
    response_body = { "data" => %w[results] }
    request_date = Date.new(2014, 7, 12)

    stub_get = stub_support_api_problem_report_daily_totals_for(request_date, response_body.to_json)

    result = @api.problem_report_daily_totals_for(request_date)

    assert_requested(stub_get)
    assert_equal response_body, result.to_hash
  end

  it "throws an exception when the support app isn't available" do
    stub_support_api_isnt_available

    assert_raises(GdsApi::HTTPServerError) { @api.create_service_feedback({}) }
  end

  describe "GET /anonymous-feedback" do
    it "fetches anonymous feedback" do
      stub_get = stub_support_api_anonymous_feedback(
        path_prefixes: ["/vat-rates"],
        page: 55,
      )

      @api.anonymous_feedback(
        path_prefixes: ["/vat-rates"],
        page: 55,
      )

      assert_requested(stub_get)
    end
  end

  describe "GET /anonymous-feedback/organisations/:organisation_slug" do
    it "fetches organisation summary" do
      slug = "hm-revenue-customs"

      stub_get = stub_support_api_anonymous_feedback_organisation_summary(slug)

      @api.organisation_summary(slug)

      assert_requested(stub_get)
    end

    it "accepts an ordering parameter" do
      slug = "hm-revenue-customs"
      ordering = "last_30_days"

      stub_get = stub_support_api_anonymous_feedback_organisation_summary(slug, ordering)

      @api.organisation_summary(slug, ordering: ordering)

      assert_requested(stub_get)
    end
  end

  describe "POST /anonymous-feedback/export-requests" do
    it "makes a POST request to the support api" do
      stub_post = stub_support_api_feedback_export_request_creation(notification_email: "foo@example.com")

      @api.create_feedback_export_request(notification_email: "foo@example.com")

      assert_requested(stub_post)
    end
  end

  describe "POST /anonymous-feedback/global-export-requests" do
    it "makes a POST request to the support API" do
      params = { from_date: "1 June 2016", to_date: "8 June 2016", notification_email: "foo@example.com" }
      stub_post = stub_support_api_global_export_request_creation(params)

      @api.create_global_export_request(params)
      assert_requested(stub_post)
    end
  end

  describe "POST /page-improvements" do
    it "makes a POST request to the support API" do
      params = { description: "The title could be better." }
      stub_post = stub_support_api_create_page_improvement(params)

      @api.create_page_improvement(params)

      assert_requested(stub_post)
    end
  end

  describe "GET /anonymous-feedback/export-requests/:id" do
    it "fetches the export request details from the API" do
      stub_get = stub_support_api_feedback_export_request(123)

      @api.feedback_export_request(123)

      assert_requested(stub_get)
    end
  end

  describe "GET /organisations" do
    it "fetches a list of organisations" do
      stub_get = stub_support_api_organisations_list

      @api.organisations_list

      assert_requested(stub_get)
    end
  end

  describe "GET /organisations/:slug" do
    it "fetches a list of organisations" do
      stub_get = stub_support_api_organisation("foo")

      @api.organisation("foo")

      assert_requested(stub_get)
    end
  end

  describe "GET /anonymous-feedback/document-types" do
    it "fetches a list of document types" do
      stub_get = stub_support_api_document_type_list

      @api.document_type_list

      assert_requested(stub_get)
    end
  end

  describe "GET /anonymous-feedback/document-types/:document_type" do
    it "fetches document type summary" do
      document_type = "smart_answer"

      stub_get = stub_support_api_anonymous_feedback_doc_type_summary(document_type)

      @api.document_type_summary(document_type)

      assert_requested(stub_get)
    end

    it "accepts an ordering parameter" do
      document_type = "smart_answer"
      ordering = "last_30_days"

      stub_get = stub_support_api_anonymous_feedback_doc_type_summary(document_type, ordering)

      @api.document_type_summary(document_type, ordering: ordering)

      assert_requested(stub_get)
    end
  end

  describe "GET /anonymous-feedback/problem-reports" do
    it "fetches a list of problem reports" do
      params = { from_date: "2016-12-12", to_date: "2016-12-13", page: 1, exclude_reviewed: true }
      stub_get = stub_support_api_problem_reports(params)

      @api.problem_reports(params)

      assert_requested(stub_get)
    end
  end

  describe "POST /anonymous-feedback/problem-reports/mark-reviewed-for-spam" do
    it "makes a PUT request to the support API" do
      params = { "1" => true, "2" => true }

      stub_post = stub_support_api_mark_reviewed_for_spam(params)

      @api.mark_reviewed_for_spam(params)

      assert_requested(stub_post)
    end
  end

  describe "GET /feedback-by-day/[date_str]" do
    it "make a GET request to the support API with default" do
      stub_get = stub_support_api_feedback_by_day(Date.today, 1, 100)

      @api.feedback_by_day(Date.today)

      assert_requested(stub_get)
    end

    it "make a GET request to the support API with page params" do
      stub_get = stub_support_api_feedback_by_day(Date.today, 2, 200)

      @api.feedback_by_day(Date.today, 2, 200)

      assert_requested(stub_get)
    end
  end
end
