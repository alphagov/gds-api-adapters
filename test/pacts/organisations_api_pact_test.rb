require "test_helper"
require "gds_api/organisations"

describe "GdsApi::Organisations pact tests" do
  include PactTest

  let(:api_client) { GdsApi::Organisations.new(organisation_api_host) }
  let(:host_agnostic_endpoint_regex) { %r{https?://(?:[^/]+)/api/organisations} }
  let(:api_client_endpoint) { "#{organisation_api_host}/api/organisations" }

  it "fetches a list of organisations" do
    organisation_api
      .given("there is a list of organisations")
      .upon_receiving("a request for the organisation list")
      .with(
        method: :get,
        path: "/api/organisations",
        headers: GdsApi::JsonClient.default_request_headers,
      )
      .will_respond_with(
        status: 200,
        body: {
          results: [
            organisation,
            organisation,
          ],
        },
        headers: {
          "Content-Type" => "application/json; charset=utf-8",
        },
      )

    api_client.organisations
  end

  describe "fetching a paginated list of organisations" do
    let(:page_one_links) do
      Pact.term(
        generate: %(<#{api_client_endpoint}?page=2>; rel="next", <#{api_client_endpoint}?page=1>; rel="self"),
        matcher: /^<#{host_agnostic_endpoint_regex}\?page=2>; rel="next", <#{host_agnostic_endpoint_regex}\?page=1>; rel="self"$/,
      )
    end
    let(:page_two_links) do
      Pact.term(
        generate: %(<#{api_client_endpoint}?page=1>; rel="previous", <#{api_client_endpoint}?page=2>; rel="self"),
        matcher: /^<#{host_agnostic_endpoint_regex}\?page=1>; rel="previous", <#{host_agnostic_endpoint_regex}\?page=2>; rel="self"$/,
      )
    end

    let(:request) do
      {
        method: :get,
        path: "/api/organisations",
        headers: GdsApi::JsonClient.default_request_headers,
      }
    end
    let(:body) do
      {
        results: Pact.each_like({}, min: 20),
        page_size: 20,
        pages: 2,
      }
    end
    let(:response) do
      {
        status: 200,
        body: body,
      }
    end

    it "handles pagination" do
      organisation_api
        .given("the organisation list is paginated, beginning at page 1")
        .upon_receiving("a request without a query param")
        .with(request.merge(query: ""))
        .will_respond_with(response.merge(headers: { "link" => page_one_links }))

      organisation_api
        .given("the organisation list is paginated, beginning at page 2")
        .upon_receiving("a request with page 2 params")
        .with(request.merge(query: "page=2"))
        .will_respond_with(response.merge(headers: { "link" => page_two_links }))

      api_client.organisations.with_subsequent_pages.count
    end
  end

  it "fetches an organisation by slug" do
    hmrc = "hm-revenue-customs"
    api_response = organisation(slug: hmrc)
    api_response["id"] = Pact.term(
      generate: %(#{api_client_endpoint}/#{hmrc}),
      matcher: /^#{host_agnostic_endpoint_regex}\/#{hmrc}$/,
    )

    organisation_api
      .given("the organisation hmrc exists")
      .upon_receiving("a request for hm-revenue-customs")
      .with(
        method: :get,
        path: "/api/organisations/#{hmrc}",
        headers: GdsApi::JsonClient.default_request_headers,
      )
      .will_respond_with(
        status: 200,
        body: api_response,
      )

    api_client.organisation(hmrc)
  end

  it "returns a 404 if no organisation exists for a given slug" do
    organisation_api
      .given("no organisation exists")
      .upon_receiving("a request for a non-existant organisation")
      .with(
        method: :get,
        path: "/api/organisations/department-for-making-life-better",
        headers: GdsApi::JsonClient.default_request_headers,
      )
      .will_respond_with(
        status: 404,
        body: "404 error",
      )

    assert_raises(GdsApi::HTTPNotFound) do
      api_client.organisation("department-for-making-life-better")
    end
  end

private

  def organisation(slug: "test-department")
    {
      "id" => Pact.like("www.gov.uk/api/organisations/#{slug}"),
      "title" => Pact.like("Test Department"),
      "updated_at" => Pact.like("2019-05-15T12:12:17.000+01:00"),
      "web_url" => Pact.like("www.gov.uk/government/organisations/#{slug}"),
      "details" => {
        "slug" => Pact.like(slug),
        "content_id" => Pact.like("b854f170-53c8-4098-bf77-e8ef42f93107"),
      },
      "analytics_identifier" => Pact.like("OT1276"),
      "child_organisations" => [],
      "superseded_organisations" => [],
    }
  end
end
