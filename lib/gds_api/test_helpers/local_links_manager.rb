require "gds_api/test_helpers/json_client_helper"

module GdsApi
  module TestHelpers
    module LocalLinksManager
      LOCAL_LINKS_MANAGER_ENDPOINT = Plek.current.find("local-links-manager")

      def stub_local_links_manager_has_a_link(authority_slug:, lgsl:, lgil:, url:, country_name: "England", status: "ok", local_custodian_code: nil)
        response = {
          "local_authority" => {
            "name" => authority_slug.capitalize,
            "snac" => "00AG",
            "tier" => "unitary",
            "homepage_url" => "http://#{authority_slug}.example.com",
            "country_name" => country_name,
            "slug" => authority_slug,
          },
          "local_interaction" => {
            "lgsl_code" => lgsl,
            "lgil_code" => lgil,
            "url" => url,
            "status" => status,
          },
        }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: { authority_slug: authority_slug, lgsl: lgsl, lgil: lgil })
          .to_return(body: response.to_json, status: 200)

        unless local_custodian_code.nil?
          stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
            .with(query: { local_custodian_code: local_custodian_code, lgsl: lgsl, lgil: lgil })
            .to_return(body: response.to_json, status: 200)
        end
      end

      def stub_local_links_manager_has_no_link(authority_slug:, lgsl:, lgil:, country_name: "England", local_custodian_code: nil)
        response = {
          "local_authority" => {
            "name" => authority_slug.capitalize,
            "snac" => "00AG",
            "tier" => "unitary",
            "homepage_url" => "http://#{authority_slug}.example.com",
            "country_name" => country_name,
            "slug" => authority_slug,
          },
        }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: { authority_slug: authority_slug, lgsl: lgsl, lgil: lgil })
          .to_return(body: response.to_json, status: 200)

        unless local_custodian_code.nil?
          stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
            .with(query: { local_custodian_code: local_custodian_code, lgsl: lgsl, lgil: lgil })
            .to_return(body: response.to_json, status: 200)
        end
      end

      def stub_local_links_manager_has_no_link_and_no_homepage_url(authority_slug:, lgsl:, lgil:, country_name: "England", local_custodian_code: nil)
        response = {
          "local_authority" => {
            "name" => authority_slug.capitalize,
            "snac" => "00AG",
            "tier" => "unitary",
            "homepage_url" => nil,
            "country_name" => country_name,
            "slug" => authority_slug,
          },
        }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: { authority_slug: authority_slug, lgsl: lgsl, lgil: lgil })
          .to_return(body: response.to_json, status: 200)

        unless local_custodian_code.nil?
          stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
            .with(query: { local_custodian_code: local_custodian_code, lgsl: lgsl, lgil: lgil })
            .to_return(body: response.to_json, status: 200)
        end
      end

      def stub_local_links_manager_request_with_missing_parameters(**parameters)
        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: convert_to_query_string_params(parameters))
          .to_return(body: {}.to_json, status: 400)
      end

      def stub_local_links_manager_request_with_invalid_parameters(**parameters)
        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: convert_to_query_string_params(parameters))
          .to_return(body: {}.to_json, status: 404)
      end

      def stub_local_links_manager_does_not_have_required_objects(authority_slug, lgsl, lgil)
        params = { authority_slug: authority_slug, lgsl: lgsl, lgil: lgil }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: params)
          .to_return(body: {}.to_json, status: 404)
      end

      def convert_to_query_string_params(parameters)
        # convert nil to an empty string, otherwise query param is not expressed correctly
        parameters.each { |key, _value| parameters[key] = "" if parameters[key].nil? }
        parameters
      end

      def stub_local_links_manager_has_a_local_authority(authority_slug, local_custodian_code: nil)
        response = {
          "local_authorities" => [
            {
              "name" => authority_slug.capitalize,
              "homepage_url" => "http://#{authority_slug}.example.com",
              "country_name" => "England",
              "tier" => "unitary",
              "slug" => authority_slug,
            },
          ],
        }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/local-authority")
          .with(query: { authority_slug: authority_slug })
          .to_return(body: response.to_json, status: 200)

        unless local_custodian_code.nil?
          stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/local-authority")
            .with(query: { local_custodian_code: local_custodian_code })
            .to_return(body: response.to_json, status: 200)
        end
      end

      def stub_local_links_manager_has_a_district_and_county_local_authority(district_slug, county_slug, local_custodian_code: nil)
        response = {
          "local_authorities" => [
            {
              "name" => district_slug.capitalize,
              "homepage_url" => "http://#{district_slug}.example.com",
              "country_name" => "England",
              "tier" => "district",
              "slug" => district_slug,
            },
            {
              "name" => county_slug.capitalize,
              "homepage_url" => "http://#{county_slug}.example.com",
              "country_name" => "England",
              "tier" => "county",
              "slug" => county_slug,
            },
          ],
        }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/local-authority")
          .with(query: { authority_slug: district_slug })
          .to_return(body: response.to_json, status: 200)

        unless local_custodian_code.nil?
          stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/local-authority")
            .with(query: { local_custodian_code: local_custodian_code })
            .to_return(body: response.to_json, status: 200)
        end
      end

      def stub_local_links_manager_request_without_local_authority_slug
        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/local-authority")
          .with(query: { authority_slug: "" })
          .to_return(body: {}.to_json, status: 400)
      end

      def stub_local_links_manager_request_without_local_custodian_code
        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/local-authority")
          .with(query: { local_custodian_code: "" })
          .to_return(body: {}.to_json, status: 400)
      end

      def stub_local_links_manager_does_not_have_an_authority(authority_slug)
        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/local-authority")
          .with(query: { authority_slug: authority_slug })
          .to_return(body: {}.to_json, status: 404)
      end

      def stub_local_links_manager_does_not_have_a_custodian_code(local_custodian_code)
        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/local-authority")
          .with(query: { local_custodian_code: local_custodian_code })
          .to_return(body: {}.to_json, status: 404)
      end

      def stub_local_links_manager_has_a_local_authority_without_homepage(authority_slug)
        response = {
          "local_authorities" => [
            {
              "name" => authority_slug.capitalize,
              "homepage_url" => "",
              "country_name" => "England",
              "tier" => "unitary",
              "slug" => authority_slug,
            },
          ],
        }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/local-authority")
          .with(query: { authority_slug: authority_slug })
          .to_return(body: response.to_json, status: 200)
      end
    end
  end
end
