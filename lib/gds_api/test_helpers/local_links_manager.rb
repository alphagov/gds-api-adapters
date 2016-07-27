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
    end
  end
end
