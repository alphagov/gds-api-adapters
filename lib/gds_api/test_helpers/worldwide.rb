require "gds_api/test_helpers/json_client_helper"
require "gds_api/test_helpers/common_responses"

module GdsApi
  module TestHelpers
    module Worldwide
      include GdsApi::TestHelpers::CommonResponses

      WORLDWIDE_API_ENDPOINT = Plek.new.website_root

      def stub_worldwide_api_has_locations(location_slugs)
        international_delegation_slugs = location_slugs.select do |slug|
          slug =~ /(delegation|mission)/
        end

        international_delegations = international_delegation_slugs.map do |slug|
          {
            "active": true,
            "analytics_identifier": "WL1",
            "content_id": "content_id_for_#{slug}",
            "iso2": slug[0..1].upcase,
            "name": titleize_slug(slug, title_case: true),
            "slug": slug,
            "updated_at": "2013-03-25T13:06:42+00:00",
          }
        end

        world_locations = (location_slugs - international_delegation_slugs).map do |slug|
          {
            "active": true,
            "analytics_identifier": "WL1",
            "content_id": "content_id_for_#{slug}",
            "iso2": slug[0..1].upcase,
            "name": titleize_slug(slug, title_case: true),
            "slug": slug,
            "updated_at": "2013-03-25T13:06:42+00:00",
          }
        end

        content_item = {
          "details": {
            "international_delegation": international_delegations,
            "world_locations": world_locations,
          },
        }

        stub_request(:get, "#{WORLDWIDE_API_ENDPOINT}/api/content/world")
            .to_return(status: 200, body: content_item.to_json)
      end

      def stub_worldwide_api_has_location(location_slug)
        stub_worldwide_api_has_locations([location_slug])
      end

      def stub_search_api_has_organisations_for_location(location_slug, organisation_content_items)
        response = {
          "results": organisation_content_items.map do |content_item|
            {
              "link": content_item["base_path"],
            }
          end,
        }

        stub_request(:get, "#{WORLDWIDE_API_ENDPOINT}/api/search.json?filter_format=worldwide_organisation&filter_world_locations=#{location_slug}")
          .to_return(status: 200, body: response.to_json)

        organisation_content_items.each do |content_item|
          stub_content_store_has_worldwide_organisation(content_item)
        end
      end

      def stub_content_store_has_worldwide_organisation(content_item)
        base_path = content_item["base_path"]

        stub_request(:get, "#{WORLDWIDE_API_ENDPOINT}/api/content#{base_path}")
          .to_return(status: 200, body: content_item.to_json)
      end
    end
  end
end
