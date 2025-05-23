require "test_helper"
require "gds_api/local_links_manager"
require "gds_api/test_helpers/local_links_manager"

describe GdsApi::LocalLinksManager do
  include GdsApi::TestHelpers::LocalLinksManager

  before do
    @base_api_url = Plek.find("local-links-manager")
    @api = GdsApi::LocalLinksManager.new(@base_api_url)
  end

  describe "#local_link" do
    describe "when making a request" do
      it "returns the local authority and local interaction details if link present" do
        stub_local_links_manager_has_a_link(
          authority_slug: "blackburn",
          lgsl: 2,
          lgil: 4,
          url: "http://blackburn.example.com/abandoned-shopping-trolleys/report",
          country_name: "England",
          status: "ok",
          title: "Shopping Trolley Hub",
        )

        expected_response = {
          "local_authority" => {
            "name" => "Blackburn",
            "snac" => "00AG",
            "gss" => "EE06000063",
            "tier" => "unitary",
            "homepage_url" => "http://blackburn.example.com",
            "country_name" => "England",
            "slug" => "blackburn",
          },
          "local_interaction" => {
            "lgsl_code" => 2,
            "lgil_code" => 4,
            "url" => "http://blackburn.example.com/abandoned-shopping-trolleys/report",
            "status" => "ok",
            "title" => "Shopping Trolley Hub",
          },
        }

        response = @api.local_link("blackburn", 2, 4)
        assert_equal expected_response, response.to_hash
      end

      it "returns the local authority details only if no link present" do
        stub_local_links_manager_has_no_link(
          authority_slug: "westminster",
          lgsl: 461,
          lgil: 8,
          country_name: "England",
          snac: "00BK",
        )

        expected_response = {
          "local_authority" => {
            "name" => "Westminster",
            "snac" => "00BK",
            "gss" => "EE06000063",
            "tier" => "unitary",
            "homepage_url" => "http://westminster.example.com",
            "country_name" => "England",
            "slug" => "westminster",
          },
        }

        response = @api.local_link("westminster", 461, 8)
        assert_equal expected_response, response.to_hash
      end

      it "returns the local authority details only without snac if no link present and no SNAC" do
        stub_local_links_manager_has_no_link(
          authority_slug: "westminster",
          lgsl: 461,
          lgil: 8,
          country_name: "England",
          snac: nil,
        )

        expected_response = {
          "local_authority" => {
            "name" => "Westminster",
            "gss" => "EE06000063",
            "tier" => "unitary",
            "homepage_url" => "http://westminster.example.com",
            "country_name" => "England",
            "slug" => "westminster",
          },
        }

        response = @api.local_link("westminster", 461, 8)
        assert_equal expected_response, response.to_hash
      end

      it "returns the local authority without a homepage url if no homepage link present" do
        stub_local_links_manager_has_no_link_and_no_homepage_url(
          authority_slug: "blackburn",
          lgsl: 2,
          lgil: 4,
          country_name: "England",
        )

        expected_response = {
          "local_authority" => {
            "name" => "Blackburn",
            "snac" => "00AG",
            "gss" => "EE06000063",
            "tier" => "unitary",
            "homepage_url" => nil,
            "country_name" => "England",
            "slug" => "blackburn",
          },
        }

        response = @api.local_link("blackburn", 2, 4)
        assert_equal expected_response, response.to_hash
      end
    end

    describe "when making request with missing required parameters" do
      it "raises HTTPClientError when authority_slug is missing" do
        stub_local_links_manager_request_with_missing_parameters(authority_slug: nil, lgsl: 2, lgil: 8)

        assert_raises GdsApi::HTTPClientError do
          @api.local_link(nil, 2, 8)
        end
      end

      it "raises HTTPClientError when LGSL is missing" do
        stub_local_links_manager_request_with_missing_parameters(authority_slug: "blackburn", lgsl: nil, lgil: 8)

        assert_raises GdsApi::HTTPClientError do
          @api.local_link("blackburn", nil, 8)
        end
      end

      it "raises HTTPClientError when LGIL is missing" do
        stub_local_links_manager_request_with_missing_parameters(authority_slug: "blackburn", lgsl: 2, lgil: nil)

        assert_raises GdsApi::HTTPClientError do
          @api.local_link("blackburn", 2, nil)
        end
      end
    end

    describe "when making request with invalid required parameters" do
      it "raises when authority_slug is invalid" do
        stub_local_links_manager_request_with_invalid_parameters(authority_slug: "hogwarts", lgsl: 2, lgil: 8)

        assert_raises(GdsApi::HTTPNotFound) do
          @api.local_link("hogwarts", 2, 8)
        end
      end

      it "raises when LGSL is invalid" do
        stub_local_links_manager_request_with_invalid_parameters(authority_slug: "blackburn", lgsl: 999, lgil: 8)

        assert_raises(GdsApi::HTTPNotFound) do
          @api.local_link("blackburn", 999, 8)
        end
      end

      it "raises when the LGSL and LGIL combination is invalid" do
        stub_local_links_manager_request_with_invalid_parameters(authority_slug: "blackburn", lgsl: 2, lgil: 9)

        assert_raises(GdsApi::HTTPNotFound) do
          @api.local_link("blackburn", 2, 9)
        end
      end
    end
  end

  describe "#local_link_by_custodian_code" do
    describe "when making a request" do
      it "returns the local authority and local interaction details if link present" do
        stub_local_links_manager_has_a_link(
          authority_slug: "blackburn",
          local_custodian_code: 2372,
          lgsl: 2,
          lgil: 4,
          url: "http://blackburn.example.com/abandoned-shopping-trolleys/report",
          country_name: "England",
          status: "ok",
        )

        expected_response = {
          "local_authority" => {
            "name" => "Blackburn",
            "snac" => "00AG",
            "gss" => "EE06000063",
            "tier" => "unitary",
            "homepage_url" => "http://blackburn.example.com",
            "country_name" => "England",
            "slug" => "blackburn",
          },
          "local_interaction" => {
            "lgsl_code" => 2,
            "lgil_code" => 4,
            "url" => "http://blackburn.example.com/abandoned-shopping-trolleys/report",
            "status" => "ok",
            "title" => nil,
          },
        }

        response = @api.local_link_by_custodian_code(2372, 2, 4)
        assert_equal expected_response, response.to_hash
      end

      it "returns the local authority details only if no link present" do
        stub_local_links_manager_has_no_link(
          authority_slug: "blackburn",
          local_custodian_code: 2372,
          lgsl: 2,
          lgil: 4,
          country_name: "England",
        )

        expected_response = {
          "local_authority" => {
            "name" => "Blackburn",
            "snac" => "00AG",
            "gss" => "EE06000063",
            "tier" => "unitary",
            "homepage_url" => "http://blackburn.example.com",
            "country_name" => "England",
            "slug" => "blackburn",
          },
        }

        response = @api.local_link_by_custodian_code(2372, 2, 4)
        assert_equal expected_response, response.to_hash
      end

      it "returns the local authority without a homepage url if no homepage link present" do
        stub_local_links_manager_has_no_link_and_no_homepage_url(
          authority_slug: "blackburn",
          local_custodian_code: 2372,
          lgsl: 2,
          lgil: 4,
          country_name: "England",
        )

        expected_response = {
          "local_authority" => {
            "name" => "Blackburn",
            "snac" => "00AG",
            "gss" => "EE06000063",
            "tier" => "unitary",
            "homepage_url" => nil,
            "country_name" => "England",
            "slug" => "blackburn",
          },
        }

        response = @api.local_link_by_custodian_code(2372, 2, 4)
        assert_equal expected_response, response.to_hash
      end
    end

    describe "when making requests with missing required parameters" do
      it "raises HTTPClientError when local_custodian_code is missing" do
        stub_local_links_manager_request_with_missing_parameters(local_custodian_code: nil, lgsl: 2, lgil: 8)

        assert_raises GdsApi::HTTPClientError do
          @api.local_link_by_custodian_code(nil, 2, 8)
        end
      end

      it "raises HTTPClientError when LGSL is missing" do
        stub_local_links_manager_request_with_missing_parameters(local_custodian_code: 2372, lgsl: nil, lgil: 8)

        assert_raises GdsApi::HTTPClientError do
          @api.local_link_by_custodian_code(2372, nil, 8)
        end
      end

      it "raises HTTPClientError when LGIL is missing" do
        stub_local_links_manager_request_with_missing_parameters(local_custodian_code: 2372, lgsl: 2, lgil: nil)

        assert_raises GdsApi::HTTPClientError do
          @api.local_link_by_custodian_code(2372, 2, nil)
        end
      end
    end

    describe "when making request with invalid required parameters" do
      it "raises when local_custodian_code is invalid" do
        stub_local_links_manager_request_with_invalid_parameters(local_custodian_code: 999, lgsl: 2, lgil: 8)

        assert_raises(GdsApi::HTTPNotFound) do
          @api.local_link_by_custodian_code(999, 2, 8)
        end
      end

      it "raises when LGSL is invalid" do
        stub_local_links_manager_request_with_invalid_parameters(local_custodian_code: 2372, lgsl: 999, lgil: 8)

        assert_raises(GdsApi::HTTPNotFound) do
          @api.local_link_by_custodian_code(2372, 999, 8)
        end
      end

      it "raises when the LGSL and LGIL combination is invalid" do
        stub_local_links_manager_request_with_invalid_parameters(local_custodian_code: 2372, lgsl: 2, lgil: 9)

        assert_raises(GdsApi::HTTPNotFound) do
          @api.local_link_by_custodian_code(2372, 2, 9)
        end
      end
    end
  end

  describe "#local_authority" do
    describe "when making a request for a local authority with a parent" do
      it "should return the local authority and its parent" do
        stub_local_links_manager_has_a_district_and_county_local_authority("blackburn", "rochester", district_snac: "test1", county_snac: "test2", district_gss: "test1gss", county_gss: "test2gss")

        expected_response = {
          "local_authorities" => [
            {
              "name" => "Blackburn",
              "homepage_url" => "http://blackburn.example.com",
              "country_name" => "England",
              "tier" => "district",
              "slug" => "blackburn",
              "gss" => "test1gss",
              "snac" => "test1",
            },
            {
              "name" => "Rochester",
              "homepage_url" => "http://rochester.example.com",
              "country_name" => "England",
              "tier" => "county",
              "slug" => "rochester",
              "gss" => "test2gss",
              "snac" => "test2",
            },
          ],
        }

        response = @api.local_authority("blackburn")
        assert_equal expected_response, response.to_hash
      end
    end

    describe "when making a request for a local authority without a parent" do
      it "should return the local authority" do
        stub_local_links_manager_has_a_local_authority("blackburn")

        expected_response = {
          "local_authorities" => [
            {
              "name" => "Blackburn",
              "homepage_url" => "http://blackburn.example.com",
              "country_name" => "England",
              "tier" => "unitary",
              "slug" => "blackburn",
              "snac" => "00AG",
              "gss" => "EE06000063",
            },
          ],
        }

        response = @api.local_authority("blackburn")
        assert_equal expected_response, response.to_hash
      end
    end

    describe "when making a request without the required parameters" do
      it "raises HTTPClientError when authority_slug is missing" do
        stub_local_links_manager_request_without_local_authority_slug

        assert_raises GdsApi::HTTPClientError do
          @api.local_authority(nil)
        end
      end
    end

    describe "when making a request with invalid required parameters" do
      it "raises when authority_slug is invalid" do
        stub_local_links_manager_does_not_have_an_authority("hogwarts")

        assert_raises(GdsApi::HTTPNotFound) { @api.local_authority("hogwarts") }
      end
    end
  end

  describe "#local_authority_by_custodian_code" do
    describe "when making a request for a local authority with a parent" do
      it "should return the local authority and its parent" do
        stub_local_links_manager_has_a_district_and_county_local_authority("blackburn", "rochester", local_custodian_code: 2372)

        expected_response = {
          "local_authorities" => [
            {
              "name" => "Blackburn",
              "homepage_url" => "http://blackburn.example.com",
              "country_name" => "England",
              "tier" => "district",
              "slug" => "blackburn",
              "gss" => "EE06000063",
              "snac" => "00AG",
            },
            {
              "name" => "Rochester",
              "homepage_url" => "http://rochester.example.com",
              "country_name" => "England",
              "tier" => "county",
              "slug" => "rochester",
              "gss" => "EE06000064",
              "snac" => "00LC",
            },
          ],
        }

        response = @api.local_authority_by_custodian_code(2372)
        assert_equal expected_response, response.to_hash
      end
    end

    describe "when making a request for a local authority without a parent" do
      it "should return the local authority" do
        stub_local_links_manager_has_a_local_authority("blackburn", local_custodian_code: 2372)

        expected_response = {
          "local_authorities" => [
            {
              "name" => "Blackburn",
              "homepage_url" => "http://blackburn.example.com",
              "country_name" => "England",
              "tier" => "unitary",
              "slug" => "blackburn",
              "snac" => "00AG",
              "gss" => "EE06000063",
            },
          ],
        }

        response = @api.local_authority_by_custodian_code(2372)
        assert_equal expected_response, response.to_hash
      end
    end

    describe "when making a request without the required parameters" do
      it "raises HTTPClientError when custodian_code is missing" do
        stub_local_links_manager_request_without_local_custodian_code

        assert_raises GdsApi::HTTPClientError do
          @api.local_authority_by_custodian_code(nil)
        end
      end
    end

    describe "when making a request with invalid required parameters" do
      it "raises when authority_slug is invalid" do
        stub_local_links_manager_does_not_have_a_custodian_code(999)

        assert_raises(GdsApi::HTTPNotFound) { @api.local_authority_by_custodian_code(999) }
      end
    end
  end
end
