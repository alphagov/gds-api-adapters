require "test_helper"
require "gds_api/worldwide"
require "gds_api/test_helpers/worldwide"

describe GdsApi::Worldwide do
  include GdsApi::TestHelpers::Worldwide
  include PactTest

  before do
    @base_api_url = GdsApi::TestHelpers::Worldwide::WORLDWIDE_API_ENDPOINT
    @api = GdsApi::Worldwide.new(@base_api_url)
  end

  describe "fetching list of world locations" do
    it "should get the world locations" do
      country_slugs = %w[the-shire rivendel rohan lorien gondor arnor mordor]
      stub_worldwide_api_has_locations(country_slugs)

      response = @api.world_locations
      assert_equal(country_slugs, response.map { |r| r.dig("details", "slug") })
    end
  end

  describe "fetching a world location" do
    it "should return the details" do
      stub_worldwide_api_has_locations(%w[rohan])

      response = @api.world_location("rohan")
      assert_equal "Rohan", response["title"]
    end

    it "raises for a non-existent location" do
      stub_worldwide_api_has_locations(%w[rohan])

      assert_raises(GdsApi::HTTPNotFound) do
        @api.world_location("non-existent")
      end
    end
  end

  describe "fetching organisations for a location" do
    it "should return the organisation details" do
      content_items = [
        {
          "base_path" => "/world/organisations/uk-trade-investment-australia",
          "title" => "UK Trade & Investment Australia",
          "updated_at" => "2023-07-31 07:00:12",
          "analytics_identifier" => "WO1",
          "links" => {
            "main_office" => [
              {
                "title" => "Australia Office",
                "web_url" => "https://www.dev.gov.uk/world/offices/australia",
                "public_updated_at" => "2023-07-30 07:00:12",
                "details" => {
                  "access_and_opening_times" => "Open 9 to 5",
                  "type" => "Other office",
                },
                "links" => {
                  contact: [
                    {
                      "details" => {
                        "email_addresses" => "australia@gov.uk",
                        "description" => "An office in Australia",
                        "contact_form_links" => "https://www.gov.uk",
                        "post_addresses" => [
                          "title" => "Office Name",
                          "street_address" => "123 A Street",
                          "postal_code" => "ABC123",
                          "locality" => "Canberra",
                          "region" => "Australian Capital Territory",
                          "world_location" => "Australia",
                        ],
                        "phone_numbers" => [
                          "title" => "Office number",
                          "number" => "1234",
                        ],
                        "services" => [
                          {
                            "title" => "Trade advice",
                            "type" => "Advice",
                          },
                        ],
                      },
                    },
                  ],
                },
              },
            ],
            "home_page_offices" => [
              {
                "title" => "A second Australia Office",
                "web_url" => "https://www.dev.gov.uk/world/offices/australia-2",
                "public_updated_at" => "2023-07-30 07:00:12",
                "details" => {
                  "access_and_opening_times" => "Open 9 to 5",
                  "type" => "Other office",
                },
                "links" => {
                  contact: [
                    {
                      "details" => {
                        "email_addresses" => "australia@gov.uk",
                        "description" => "An office in Australia",
                        "contact_form_links" => "https://www.gov.uk",
                        "post_addresses" => [
                          "title" => "Office Name",
                          "street_address" => "456 A Street",
                          "postal_code" => "ABC456",
                          "locality" => "Canberra",
                          "region" => "Australian Capital Territory",
                          "world_location" => "Australia",
                        ],
                        "phone_numbers" => [
                          "title" => "Office number",
                          "number" => "5678",
                        ],
                        "services" => [
                          {
                            "title" => "Trade advice",
                            "type" => "Advice",
                          },
                        ],
                      },
                    },
                  ],
                },
              },
            ],
            "sponsoring_organisations" => [
              {
                "title" => "Foreign, Commonwealth and Development Office",
                "web_url" => "https://www.fcdo.gov.uk",
                "details" => {
                  "acronym" => "FCDO",
                },
              },
            ],
          },
        },
        {
          "base_path" => "/world/organisations/british-high-commission-canberra",
          "title" => "British High Commission Canberra",
          "updated_at" => "2023-07-31 09:00:12",
          "analytics_identifier" => "WO2",
        },
      ]

      stub_search_api_has_organisations_for_location("australia", content_items)

      response = @api.organisations_for_world_location("australia")
      assert_equal(
        [
          {
            "id" => "#{Plek.new.website_root}/world/organisations/uk-trade-investment-australia",
            "title" => "UK Trade & Investment Australia",
            "format" => "Worldwide Organisation",
            "updated_at" => "2023-07-31 07:00:12",
            "web_url" => "#{Plek.new.website_root}/world/organisations/uk-trade-investment-australia",
            "details" => {
              "slug" => "uk-trade-investment-australia",
            },
            "analytics_identifier" => "WO1",
            "offices" => {
              "main" => {
                "title" => "Australia Office",
                "format" => "World Office",
                "updated_at" => "2023-07-30 07:00:12",
                "web_url" => "https://www.dev.gov.uk/world/offices/australia",
                "details" => {
                  "email" => "australia@gov.uk",
                  "description" => "An office in Australia",
                  "contact_form_url" => "https://www.gov.uk",
                  "access_and_opening_times" => "Open 9 to 5",
                  "type" => "Other office",
                },
                "address" => {
                  "adr" => {
                    "fn" => "Office Name",
                    "street-address" => "123 A Street",
                    "postal-code" => "ABC123",
                    "locality" => "Canberra",
                    "region" => "Australian Capital Territory",
                    "country-name" => "Australia",
                  },
                },
                "contact_numbers" => [
                  {
                    "label" => "Office number",
                    "number" => "1234",
                  },
                ],
                "services" => [
                  {
                    title: "Trade advice",
                    type: "Advice",
                  },
                ],
              },
              "other" => [
                {
                  "title" => "A second Australia Office",
                  "format" => "World Office",
                  "updated_at" => "2023-07-30 07:00:12",
                  "web_url" => "https://www.dev.gov.uk/world/offices/australia-2",
                  "details" => {
                    "email" => "australia@gov.uk",
                    "description" => "An office in Australia",
                    "contact_form_url" => "https://www.gov.uk",
                    "access_and_opening_times" => "Open 9 to 5",
                    "type" => "Other office",
                  },
                  "address" => {
                    "adr" => {
                      "fn" => "Office Name",
                      "street-address" => "456 A Street",
                      "postal-code" => "ABC456",
                      "locality" => "Canberra",
                      "region" => "Australian Capital Territory",
                      "country-name" => "Australia",
                    },
                  },
                  "contact_numbers" => [
                    {
                      "label" => "Office number",
                      "number" => "5678",
                    },
                  ],
                  "services" => [
                    {
                      title: "Trade advice",
                      type: "Advice",
                    },
                  ],
                },
              ],
            },
            "sponsors" => [
              {
                "title" => "Foreign, Commonwealth and Development Office",
                "web_url" => "https://www.fcdo.gov.uk",
                "details" => {
                  "acronym" => "FCDO",
                },
              },
            ],
          },
          {
            "id" => "#{Plek.new.website_root}/world/organisations/british-high-commission-canberra",
            "title" => "British High Commission Canberra",
            "format" => "Worldwide Organisation",
            "updated_at" => "2023-07-31 09:00:12",
            "web_url" => "#{Plek.new.website_root}/world/organisations/british-high-commission-canberra",
            "details" => {
              "slug" => "british-high-commission-canberra",
            },
            "analytics_identifier" => "WO2",
            "offices" => {
              "main" => {},
              "other" => [],
            },
            "sponsors" => [],
          },
        ],
        response,
      )
    end
  end
end
