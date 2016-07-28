require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module LocalLinksManager

      LOCAL_LINKS_MANAGER_ENDPOINT = Plek.current.find('local_links_manager')

      def local_links_manager_has_a_link(authority_slug:, lgsl:, lgil:, url:)
        response = {
          "local_authority" => {
            "name" => authority_slug.capitalize,
            "snac" => "00AG",
            "tier" => "unitary",
            "homepage_url" => "http://#{authority_slug}.example.com",
          },
          "local_interaction" => {
            "lgsl_code" => lgsl,
            "lgil_code" => lgil,
            "url" => url,
          }
        }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: {authority_slug: authority_slug, lgsl: lgsl, lgil: lgil})
          .to_return(body: response.to_json, status: 200)
      end

      def local_links_manager_has_no_link(authority_slug:, lgsl:, lgil:)
        response = {
          "local_authority" => {
            "name" => authority_slug.capitalize,
            "snac" => "00AG",
            "tier" => "unitary",
            "homepage_url" => "http://#{authority_slug}.example.com",
          },
        }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: {authority_slug: authority_slug, lgsl: lgsl, lgil: lgil})
          .to_return(body: response.to_json, status: 200)
      end

      def local_links_manager_has_no_link_and_no_homepage_url(authority_slug:, lgsl:, lgil:)
        response = {
          "local_authority" => {
            "name" => authority_slug.capitalize,
            "snac" => "00AG",
            "tier" => "unitary",
            "homepage_url" => nil,
          },
        }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: {authority_slug: authority_slug, lgsl: lgsl, lgil: lgil})
          .to_return(body: response.to_json, status: 200)
      end

      def local_links_manager_has_a_fallback_link(authority_slug:, lgsl:, lgil:, url:)
        response = {
          "local_authority" => {
            "name" => authority_slug.capitalize,
            "snac" => "00AG",
            "tier" => "unitary",
            "homepage_url" => "http://#{authority_slug}.example.com",
          },
          "local_interaction" => {
            "lgsl_code" => lgsl,
            "lgil_code" => lgil,
            "url" => url,
          }
        }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: {authority_slug: authority_slug, lgsl: lgsl})
          .to_return(body: response.to_json, status: 200)
      end

      def local_links_manager_has_no_fallback_link(authority_slug:, lgsl:)
        response = {
          "local_authority" => {
            "name" => authority_slug.capitalize,
            "snac" => "00AG",
            "tier" => "unitary",
            "homepage_url" => "http://#{authority_slug}.example.com",
          },
        }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: {authority_slug: authority_slug, lgsl: lgsl})
          .to_return(body: response.to_json, status: 200)
      end

      def local_links_manager_has_a_local_authority(authority_slug)
        response = {
          "local_authorities" => [
            {
              "name" => authority_slug.capitalize,
              "homepage_url" => "http://#{authority_slug}.example.com",
              "type" => "unitary"
            }
          ]
        }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/local_authority")
          .with(query: {authority_slug: authority_slug})
          .to_return(body: response.to_json, status: 200)
      end

      def local_links_manager_has_a_district_and_county_local_authority(district_slug, county_slug)
        response = {
          "local_authorities" => [
            {
              "name" => district_slug.capitalize,
              "homepage_url" => "http://#{district_slug}.example.com",
              "type" => "district"
            },
            {
              "name" => county_slug.capitalize,
              "homepage_url" => "http://#{county_slug}.example.com",
              "type" => "county"
            }
          ],
        }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/local_authority")
          .with(query: {authority_slug: district_slug})
          .to_return(body: response.to_json, status: 200)
      end
    end
  end
end
