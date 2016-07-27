require "test_helper"
require "gds_api/local_links_manager"
require "gds_api/test_helpers/local_links_manager"
require 'pry'

describe GdsApi::LocalLinksManager do
  include GdsApi::TestHelpers::LocalLinksManager

  before do
    @base_api_url = Plek.current.find("local_links_manager")
    @api = GdsApi::LocalLinksManager.new(@base_api_url)
  end

  describe "#link" do
    describe "when making request for specific LGIL" do
      it "returns the local authority and local interaction details if link present" do
        local_links_manager_has_a_link(
          authority_slug: "blackburn",
          lgsl: 2,
          lgil: 4,
          url: "http://blackburn.example.com/abandoned-shopping-trolleys/report"
        )

        expected_response = {
          "local_authority" => {
            "name" => "Blackburn",
              "snac" => "00AG",
              "tier" => "unitary",
              "homepage_url" => "http://blackburn.example.com",
          },
          "local_interaction" => {
            "lgsl_code" => 2,
            "lgil_code" => 4,
            "url" => "http://blackburn.example.com/abandoned-shopping-trolleys/report",
          }
        }

        response = @api.local_link("blackburn", 2, 4)
        assert_equal expected_response, response.to_hash
      end

      it "returns the local authority details only if no link present" do
        local_links_manager_has_no_link(
          authority_slug: "blackburn",
          lgsl: 2,
          lgil: 4,
        )

        expected_response = {
          "local_authority" => {
            "name" => "Blackburn",
              "snac" => "00AG",
              "tier" => "unitary",
              "homepage_url" => "http://blackburn.example.com",
          },
        }

        response = @api.local_link("blackburn", 2, 4)
        assert_equal expected_response, response.to_hash
      end

      it 'returns the local authority without a homepage url if no homepage link present' do
        local_links_manager_has_no_link_and_no_homepage_url(
          authority_slug: "blackburn",
          lgsl: 2,
          lgil: 4,
        )

        expected_response = {
          "local_authority" => {
            "name" => "Blackburn",
              "snac" => "00AG",
              "tier" => "unitary",
              "homepage_url" => nil,
          },
        }

        response = @api.local_link("blackburn", 2, 4)
        assert_equal expected_response, response.to_hash
      end
    end

    describe "when making request without LGIL" do
      it "returns the local authority and local interaction details if link present" do
        local_links_manager_has_a_fallback_link(
          authority_slug: "blackburn",
          lgsl: 2,
          lgil: 3,
          url: "http://blackburn.example.com/abandoned-shopping-trolleys/report"
        )

        expected_response = {
          "local_authority" => {
            "name" => "Blackburn",
              "snac" => "00AG",
              "tier" => "unitary",
              "homepage_url" => "http://blackburn.example.com",
          },
          "local_interaction" => {
            "lgsl_code" => 2,
            "lgil_code" => 3,
            "url" => "http://blackburn.example.com/abandoned-shopping-trolleys/report",
          }
        }

        response = @api.local_link("blackburn", 2)
        assert_equal expected_response, response.to_hash
      end

      it "returns the local authority and local interaction details if no link present" do
        local_links_manager_has_no_fallback_link(
          authority_slug: "blackburn",
          lgsl: 2
        )

        expected_response = {
          "local_authority" => {
            "name" => "Blackburn",
              "snac" => "00AG",
              "tier" => "unitary",
              "homepage_url" => "http://blackburn.example.com",
          },
        }

        response = @api.local_link("blackburn", 2)
        assert_equal expected_response, response.to_hash
      end
    end

    describe "when making request with missing required parameters" do
      it "raises HTTPClientError when authority_slug is missing" do
        local_links_manager_request_with_missing_parameters(nil, 2)

        assert_raises GdsApi::HTTPClientError do
          @api.local_link(nil, 2)
        end
      end

      it "raises HTTPClientError when LGSL is missing" do
        local_links_manager_request_with_missing_parameters('blackburn', nil)

        assert_raises GdsApi::HTTPClientError do
          @api.local_link('blackburn', nil)
        end
      end
    end

    describe "when making request with invalid required parameters" do
      it "returns nil when authority_slug is invalid" do
        local_links_manager_does_not_have_required_objects("hogwarts", 2)

        response = @api.local_link("hogwarts", 2)
        assert_equal nil, response
      end

      it "returns nil when LGSL is invalid" do
        local_links_manager_does_not_have_required_objects("blackburn", 999)

        response = @api.local_link("blackburn", 999)
        assert_equal nil, response
      end

      it "returns nil when the LGSL and LGIL combination is invalid" do
        local_links_manager_does_not_have_required_objects("blackburn", 2, 9)

        response = @api.local_link("blackburn", 2, 9)
        assert_equal nil, response
      end
    end
  end
end
