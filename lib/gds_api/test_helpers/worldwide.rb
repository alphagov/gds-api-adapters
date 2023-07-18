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

      def stub_worldwide_api_has_organisations_for_location(location_slug, json_or_hash)
        json = json_or_hash.is_a?(Hash) ? json_or_hash.to_json : json_or_hash
        url = "#{WORLDWIDE_API_ENDPOINT}/api/world-locations/#{location_slug}/organisations"
        stub_request(:get, url)
          .to_return(status: 200, body: json, headers: { "Link" => "<#{url}; rel\"self\"" })
      end

      def stub_worldwide_api_has_no_organisations_for_location(location_slug)
        details = { "results" => [], "total" => 0, "_response_info" => { "status" => "ok" } }
        url = "#{WORLDWIDE_API_ENDPOINT}/api/world-locations/#{location_slug}/organisations"
        stub_request(:get, url)
          .to_return(status: 200, body: details.to_json, headers: { "Link" => "<#{url}; rel\"self\"" })
      end
    end
  end
end
