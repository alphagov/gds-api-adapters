require "gds_api/test_helpers/json_client_helper"
require "gds_api/test_helpers/common_responses"

module GdsApi
  module TestHelpers
    module Worldwide
      include GdsApi::TestHelpers::CommonResponses

      WORLDWIDE_API_ENDPOINT = Plek.new.website_root

      # Sets up the index endpoints for the given country slugs
      # The stubs are setup to paginate in chunks of 20
      #
      # This also sets up the individual endpoints for each slug
      # by calling stub_worldwide_api_has_location below
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

        location_slugs.each { |s| stub_worldwide_api_has_location(s) }
        pages = []
        location_slugs.each_slice(20) do |slugs|
          pages << slugs.map { |s| stub_worldwide_api_has_locations(s) }
        end

        pages.each_with_index do |page, i|
          page_details = plural_response_base.merge(
            "results" => page,
            "total" => location_slugs.size,
            "pages" => pages.size,
            "current_page" => i + 1,
            "page_size" => 20,
            "start_index" => i * 20 + 1,
          )

          links = { self: "#{WORLDWIDE_API_ENDPOINT}/api/world-locations?page=#{i + 1}" }
          links[:next] = "#{WORLDWIDE_API_ENDPOINT}/api/world-locations?page=#{i + 2}" if pages[i + 1]
          links[:previous] = "#{WORLDWIDE_API_ENDPOINT}/api/world-locations?page=#{i}" unless i.zero?
          page_details["_response_info"]["links"] = []
          link_headers = []
          links.each do |rel, href|
            page_details["_response_info"]["links"] << { "rel" => rel, "href" => href }
            link_headers << "<#{href}>; rel=\"#{rel}\""
          end

          stub_request(:get, links[:self])
            .to_return(status: 200, body: page_details.to_json, headers: { "Link" => link_headers.join(", ") })

          next unless i.zero?

          # First page exists at URL with and without page param
          stub_request(:get, links[:self].sub(/\?page=1/, ""))
            .to_return(status: 200, body: page_details.to_json, headers: { "Link" => link_headers.join(", ") })
        end
      end

      def stub_worldwide_api_has_location(location_slug, details = nil)
        details ||= world_location_for_slug(location_slug)
        stub_request(:get, "#{WORLDWIDE_API_ENDPOINT}/api/world-locations/#{location_slug}")
          .to_return(status: 200, body: details.to_json)
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

      def world_location_for_slug(slug)
        singular_response_base.merge(stub_worldwide_api_has_locations(slug))
      end

      # Constructs a sample world_location
      #
      # if the slug contains 'delegation' or 'mission' the format will be set to 'International delegation'
      # othersiwe it will be set to 'World location'
      def stub_worldwide_api_has_locations(slug)
        {
          "id" => "https://www.gov.uk/api/world-locations/#{slug}",
          "title" => titleize_slug(slug, title_case: true),
          "format" => (slug =~ /(delegation|mission)/ ? "International delegation" : "World location"),
          "updated_at" => "2013-03-25T13:06:42+00:00",
          "web_url" => "https://www.gov.uk/government/world/#{slug}",
          "details" => {
            "slug" => slug,
            "iso2" => slug[0..1].upcase,
          },
          "organisations" => {
            "id" => "https://www.gov.uk/api/world-locations/#{slug}/organisations",
            "web_url" => "https://www.gov.uk/government/world/#{slug}#organisations",
          },
          "content_id" => "content_id_for_#{slug}",
        }
      end
    end
  end
end
