require "test_helper"
require "gds_api/local_links_manager"
require "gds_api/test_helpers/local_links_manager"

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
  end
end
