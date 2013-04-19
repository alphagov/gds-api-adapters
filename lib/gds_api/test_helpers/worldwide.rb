require 'gds_api/test_helpers/json_client_helper'
require 'gds_api/test_helpers/common_responses'

module GdsApi
  module TestHelpers
    module Worldwide
      include GdsApi::TestHelpers::CommonResponses

      WORLDWIDE_API_ENDPOINT = Plek.current.find('whitehall-admin')

      def worldwide_api_has_locations(location_slugs)
        pages = []
        location_slugs.each_slice(20) do |slugs|
          pages << slugs.map {|s| world_location_details_for_slug(s) }
        end

        pages.each_with_index do |page, i|
          page_details = plural_response_base.merge({
            "results" => page,
            "total" => location_slugs.size,
            "pages" => pages.size,
            "current_page" => i + 1,
            "page_size" => 20,
            "start_index" => i * 20 + 1,
          })

          links = {:self => "#{WORLDWIDE_API_ENDPOINT}/api/world-locations?page=#{i + 1}" }
          links[:next] = "#{WORLDWIDE_API_ENDPOINT}/api/world-locations?page=#{i + 2}" if pages[i+1]
          links[:previous] = "#{WORLDWIDE_API_ENDPOINT}/api/world-locations?page=#{i}" unless i == 0
          page_details["_response_info"]["links"] = []
          link_headers = []
          links.each do |rel, href|
            page_details["_response_info"]["links"] << {"rel" => rel, "href" => href}
            link_headers << "<#{href}>; rel=\"#{rel}\""
          end

          stub_request(:get, links[:self]).
            to_return(:status => 200, :body => page_details.to_json, :headers => {"Link" => link_headers.join(", ")})
          if i == 0
            # First page exists at URL with and without page param
            stub_request(:get, links[:self].sub(/\?page=1/, '')).
              to_return(:status => 200, :body => page_details.to_json, :headers => {"Link" => link_headers.join(", ")})
          end
        end
      end

      def worldwide_api_has_location(location_slug, details=nil)
        details ||= world_location_for_slug(location_slug)
        stub_request(:get, "#{WORLDWIDE_API_ENDPOINT}/api/world-locations/#{location_slug}").
          to_return(:status => 200, :body => details.to_json)
      end

      def worldwide_api_does_not_have_location(location_slug)
        stub_request(:get, "#{WORLDWIDE_API_ENDPOINT}/api/world-locations/#{location_slug}").to_return(:status => 404)
      end

      def worldwide_api_has_organisations_for_location(location_slug, details)
        url = "#{WORLDWIDE_API_ENDPOINT}/api/world-locations/#{location_slug}/organisations"
        stub_request(:get, url).
          to_return(:status => 200, :body => details.to_json, :headers => {"Link" => "<#{url}; rel\"self\""})
      end

      def world_location_for_slug(slug)
        singular_response_base.merge(world_location_details_for_slug(slug))
      end

      def world_location_details_for_slug(slug)
        {
          "id" => "https://www.gov.uk/api/world-locations/#{slug}",
          "title" => titleize_slug(slug),
          "format" => "World location",
          "updated_at" => "2013-03-25T13:06:42+00:00",
          "web_url" => "https://www.gov.uk/government/world/#{slug}",
          "details" => {
            "slug" => slug,
            "iso2" => slug[0..1].upcase,
          },
          "organisations" => {
            "id" => "https://www.gov.uk/api/world-locations/#{slug}/organisations",
            "web_url" => "https://www.gov.uk/government/world/#{slug}#organisations"
          },
        }
      end

    end
  end
end
