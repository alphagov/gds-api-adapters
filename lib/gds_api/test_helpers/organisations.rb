require 'gds_api/test_helpers/json_client_helper'
require 'gds_api/test_helpers/common_responses'
require 'plek'
require 'securerandom'

module GdsApi
  module TestHelpers
    module Organisations
      include GdsApi::TestHelpers::CommonResponses

      ORGANISATIONS_API_ENDPOINT = Plek.current.find('whitehall-admin')
      PUBLIC_HOST = Plek.current.find('www')

      def organisations_api_has_organisations(organisation_slugs)
        bodies = organisation_slugs.map { |slug| organisation_for_slug(slug) }
        organisations_api_has_organisations_with_bodies(bodies)
      end

      # Sets up the index endpoints for the given organisation slugs
      # The stubs are setup to paginate in chunks of 20
      #
      # This also sets up the individual endpoints for each slug
      # by calling organisations_api_has_organisation below
      def organisations_api_has_organisations_with_bodies(organisation_bodies)
        # Stub API call to the endpoint for an individual organisation
        organisation_bodies.each do |body|
          slug = body["details"]["slug"]
          organisations_api_has_organisation(slug, body)
        end

        pages = []
        organisation_bodies.each_slice(20) do |bodies|
          pages << bodies
        end

        pages.each_with_index do |page, i|
          page_details = plural_response_base.merge("results" => page,
            "total" => organisation_bodies.size,
            "pages" => pages.size,
            "current_page" => i + 1,
            "page_size" => 20,
            "start_index" => i * 20 + 1)

          links = { self: "#{ORGANISATIONS_API_ENDPOINT}/api/organisations?page=#{i + 1}" }
          links[:next] = "#{ORGANISATIONS_API_ENDPOINT}/api/organisations?page=#{i + 2}" if pages[i + 1]
          links[:previous] = "#{ORGANISATIONS_API_ENDPOINT}/api/organisations?page=#{i}" unless i == 0
          page_details["_response_info"]["links"] = []
          link_headers = []
          links.each do |rel, href|
            page_details["_response_info"]["links"] << { "rel" => rel, "href" => href }
            link_headers << "<#{href}>; rel=\"#{rel}\""
          end

          stub_request(:get, links[:self]).
            to_return(status: 200, body: page_details.to_json, headers: { "Link" => link_headers.join(", ") })
          if i == 0
            # First page exists at URL with and without page param
            stub_request(:get, links[:self].sub(/\?page=1/, '')).
              to_return(status: 200, body: page_details.to_json, headers: { "Link" => link_headers.join(", ") })
          end
        end

        if pages.empty?
          # If there are no pages - and so no organisations specified - then stub /api/organisations.
          stub_request(:get, "#{ORGANISATIONS_API_ENDPOINT}/api/organisations").to_return(status: 200, body: plural_response_base.to_json, headers: {})
        end
      end

      def organisations_api_has_organisation(organisation_slug, details = nil)
        details ||= organisation_for_slug(organisation_slug)
        stub_request(:get, "#{ORGANISATIONS_API_ENDPOINT}/api/organisations/#{organisation_slug}").
          to_return(status: 200, body: details.to_json)
      end

      def organisations_api_does_not_have_organisation(organisation_slug)
        stub_request(:get, "#{ORGANISATIONS_API_ENDPOINT}/api/organisations/#{organisation_slug}").to_return(status: 404)
      end

      def organisation_for_slug(slug)
        singular_response_base.merge(organisation_details_for_slug(slug))
      end

      # Constructs a sample organisation
      #
      # if the slug contains 'ministry' the format will be set to 'Ministerial department'
      # otherwise it will be set to 'Executive agency'
      def organisation_details_for_slug(slug, content_id = SecureRandom.uuid)
        {
          "id" => "#{ORGANISATIONS_API_ENDPOINT}/api/organisations/#{slug}",
          "title" => titleize_slug(slug, title_case: true),
          "format" => (slug =~ /ministry/ ? "Ministerial department" : "Executive agency"),
          "updated_at" => "2013-03-25T13:06:42+00:00",
          "web_url" => "#{PUBLIC_HOST}/government/organisations/#{slug}",
          "details" => {
            "slug" => slug,
            "abbreviation" => acronymize_slug(slug),
            "logo_formatted_name" => titleize_slug(slug, title_case: true),
            "organisation_brand_colour_class_name" => slug,
            "organisation_logo_type_class_name" => (slug =~ /ministry/ ? "single-identity" : "eo"),
            "closed_at" => nil,
            "govuk_status" => (slug =~ /ministry/ ? "live" : "joining"),
            "content_id" => content_id,
          },
          "parent_organisations" => [
            {
              "id" => "#{ORGANISATIONS_API_ENDPOINT}/api/organisations/#{slug}-parent-1",
              "web_url" => "#{PUBLIC_HOST}/government/organisations/#{slug}-parent-1"
            },
          ],
          "child_organisations" => [
            {
              "id" => "#{ORGANISATIONS_API_ENDPOINT}/api/organisations/#{slug}-child-1",
              "web_url" => "#{PUBLIC_HOST}/government/organisations/#{slug}-child-1"
            },
          ],
        }
      end
    end
  end
end
