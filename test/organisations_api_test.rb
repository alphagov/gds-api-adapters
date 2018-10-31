require_relative 'test_helper'
require 'gds_api/organisations'
require 'gds_api/test_helpers/organisations'

describe GdsApi::Organisations do
  include GdsApi::TestHelpers::Organisations

  before do
    @base_api_url = Plek.new.website_root
    @api = GdsApi::Organisations.new(@base_api_url)
  end

  describe "fetching list of organisations" do
    it "should get the organisations" do
      organisation_slugs = %w(ministry-of-fun tea-agency)
      organisations_api_has_organisations(organisation_slugs)

      response = @api.organisations
      assert_equal organisation_slugs, response.map { |r| r['details']['slug'] }
      assert_equal "Tea Agency", response['results'][1]['title']
    end

    it "should handle the pagination" do
      organisation_slugs = (1..50).map { |n| "organisation-#{n}" }
      organisations_api_has_organisations(organisation_slugs)

      response = @api.organisations
      assert_equal(
        organisation_slugs,
        response.with_subsequent_pages.map { |r| r['details']['slug'] }
      )
    end

    it "should raise error if endpoint 404s" do
      stub_request(:get, "#{@base_api_url}/api/organisations").to_return(status: 404)
      assert_raises GdsApi::HTTPNotFound do
        @api.organisations
      end
    end
  end

  describe "fetching an organisation" do
    it "should return the details" do
      organisations_api_has_organisation('ministry-of-fun')

      response = @api.organisation('ministry-of-fun')
      assert_equal 'Ministry Of Fun', response['title']
    end

    it "should raise for a non-existent organisation" do
      organisations_api_does_not_have_organisation('non-existent')

      assert_raises(GdsApi::HTTPNotFound) do
        @api.organisation('non-existent')
      end
    end
  end
end
