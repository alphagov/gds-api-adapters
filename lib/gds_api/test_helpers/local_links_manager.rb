require "gds_api/test_helpers/json_client_helper"

module GdsApi
  module TestHelpers
    module LocalLinksManager
      LOCAL_LINKS_MANAGER_ENDPOINT = Plek.current.find("local-links-manager")

      def local_authority_example_link_response
        {
          "local_authority" => {
            "name" => authority_slug.capitalize,
            "snac" => "00AG",
            "tier" => "unitary",
            "homepage_url" => "http://#{authority_slug}.example.com",
            "country_name" => country_name,
          },
          "local_interaction" => {
            "lgsl_code" => lgsl,
            "lgil_code" => lgil,
            "url" => url,
            "status" => status,
          },
        }
      end

      def stub_local_links_manager_has_a_link_with_slug_with_slug(authority_slug:, lgsl:, lgil:, url:, country_name: "England", status: "ok")
        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: { authority_slug: authority_slug, lgsl: lgsl, lgil: lgil })
          .to_return(body: local_authority_example_link_response.to_json, status: 200)
      end

      def stub_local_links_manager_has_a_link_with_gss(gss:, lgsl:, lgil:, url:, country_name: "England", status: "ok")
        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: { gss: gss, lgsl: lgsl, lgil: lgil })
          .to_return(body: local_authority_example_link_response.to_json, status: 200)
      end

      def local_authority_example_no_link_response
        {
          "local_authority" => {
            "name" => authority_slug.capitalize,
            "snac" => "00AG",
            "tier" => "unitary",
            "homepage_url" => "http://#{authority_slug}.example.com",
            "country_name" => country_name,
          },
        }
      end

      def stub_local_links_manager_has_no_link_with_slug(authority_slug:, lgsl:, lgil:, country_name: "England")
        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: { authority_slug: authority_slug, lgsl: lgsl, lgil: lgil })
          .to_return(body: local_authority_example_no_link_response.to_json, status: 200)
      end

      def stub_local_links_manager_has_no_link_with_gss(gss:, lgsl:, lgil:, country_name: "England")
        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: { gss: gss, lgsl: lgsl, lgil: lgil })
          .to_return(body: local_authority_example_no_link_response.to_json, status: 200)
      end

      def local_authority_example_no_link_and_ho_homepage_url_response
        {
          "local_authority" => {
            "name" => authority_slug.capitalize,
            "snac" => "00AG",
            "tier" => "unitary",
            "homepage_url" => nil,
            "country_name" => country_name,
          },
        }
      end

      def stub_local_links_manager_has_no_link_and_no_homepage_url_with_slug(authority_slug:, lgsl:, lgil:, country_name: "England")
        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: { authority_slug: authority_slug, lgsl: lgsl, lgil: lgil })
          .to_return(body: local_authority_example_no_link_and_ho_homepage_url_response.to_json, status: 200)
      end

      def stub_local_links_manager_has_no_link_and_no_homepage_url_with_gss(gss:, lgsl:, lgil:, country_name: "England")
        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: { gss: gss, lgsl: lgsl, lgil: lgil })
          .to_return(body: local_authority_example_no_link_and_ho_homepage_url_response.to_json, status: 200)
      end

      def stub_local_links_manager_request_with_missing_parameters(authority_slug, lgsl, lgil)
        # convert nil to an empty string, otherwise query param is not expressed correctly
        params = {
          authority_slug: authority_slug || "",
          lgsl: lgsl || "",
          lgil: lgil || "",
        }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: params)
          .to_return(body: {}.to_json, status: 400)
      end

      def stub_local_links_manager_does_not_have_required_objects(authority_slug, lgsl, lgil)
        params = { authority_slug: authority_slug, lgsl: lgsl, lgil: lgil }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/link")
          .with(query: params)
          .to_return(body: {}.to_json, status: 404)
      end

      def stub_local_links_manager_has_a_local_authority(authority_slug)
        response = {
          "local_authorities" => [
            {
              "name" => authority_slug.capitalize,
              "homepage_url" => "http://#{authority_slug}.example.com",
              "country_name" => "England",
              "tier" => "unitary",
            },
          ],
        }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/local-authority")
          .with(query: { authority_slug: authority_slug })
          .to_return(body: response.to_json, status: 200)
      end

      def stub_local_links_manager_has_a_district_and_county_local_authority(district_slug, county_slug)
        response = {
          "local_authorities" => [
            {
              "name" => district_slug.capitalize,
              "homepage_url" => "http://#{district_slug}.example.com",
              "country_name" => "England",
              "tier" => "district",
            },
            {
              "name" => county_slug.capitalize,
              "homepage_url" => "http://#{county_slug}.example.com",
              "country_name" => "England",
              "tier" => "county",
            },
          ],
        }

        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/local-authority")
          .with(query: { authority_slug: district_slug })
          .to_return(body: response.to_json, status: 200)
      end

      def stub_local_links_manager_request_without_local_authority_slug
        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/local-authority")
          .with(query: { authority_slug: "" })
          .to_return(body: {}.to_json, status: 400)
      end

      def stub_local_links_manager_does_not_have_an_authority(authority_slug)
        stub_request(:get, "#{LOCAL_LINKS_MANAGER_ENDPOINT}/api/local-authority")
          .with(query: { authority_slug: authority_slug })
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
