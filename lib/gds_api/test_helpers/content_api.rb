require 'gds_api/test_helpers/json_client_helper'
require 'cgi'

module GdsApi
  module TestHelpers
    module ContentApi
      CONTENT_API_ENDPOINT = 'https://contentapi.test.alphagov.co.uk'

      def content_api_has_root_sections(slugs)
        body = plural_response_base.merge(
          "results" => slugs.map do |slug|
            {
              "id" => "http://contentapi.test.gov.uk/tags/#{CGI.escape(slug)}.json",
              "web_url" => nil,
              "title" => titleize_slug(slug),
              "details" => {
                "type" => "section",
                "description" => "#{slug} description"
              },
              "parent" => nil,
              "content_with_tag" => {
                "id" => "http://contentapi.test.gov.uk/with_tag.json?tag=#{CGI.escape(slug)}",
                "web_url" => "http://www.test.gov.uk/browse/#{slug}"
              }
            }
          end
        )
        url = "#{CONTENT_API_ENDPOINT}/tags.json?type=section"
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end

      def content_api_has_an_artefact(slug, body = artefact_for_slug(slug))
        url = "#{CONTENT_API_ENDPOINT}/#{slug}.json"
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end

      def content_api_does_not_have_an_artefact(slug)
        body = {
          "_response_info" => {
            "status" => "not found"
          }
        }
        url = "#{CONTENT_API_ENDPOINT}/#{slug}.json"
        stub_request(:get, url).to_return(status: 404, body: body.to_json, headers: {})
      end

      def stub_content_api_default_artefact
        stub_request(:get, %r{\A#{CONTENT_API_ENDPOINT}/[a-z0-9-]+\.json}).to_return { |request|
          slug = request.uri.path.split('/').last.chomp('.json')
          {:body => artefact_for_slug(slug).to_json}
        }
      end

      def artefact_for_slug(slug)
        singular_response_base.merge(
          "title" => titleize_slug(slug),
          "id" => "http://contentapi.test.gov.uk/#{slug}.json",
          "web_url" => "http://frontend.test.gov.uk/#{slug}",
          "details" => {
            "need_id" => "1234",
            "business_proposition" => false, # To be removed and replaced with proposition tags
            "format" => "Guide",
            "alternative_title" => "",
            "overview" => "This is an overview",
            "video_summary" => "",
            "video_url" => "",
            "parts" => [
              {
                "id" => "overview",
                "order" => 1,
                "title" => "Overview",
                "body" => "<p>Some content</p>"
              },
              {
                "id" => "#{slug}-part-2",
                "order" => 2,
                "title" => "How to make a nomination",
                "body" => "<p>Some more content</p>"
              }
            ]
          },
          "tags" => [],
          "related" => []
        )
      end

      def artefact_for_slug_in_a_section(slug, section_slug)
        artefact = artefact_for_slug(slug)
        artefact["tags"] << tag_for_slug(section_slug, "section")
        artefact
      end

      def artefact_for_slug_in_a_subsection(slug, subsection_slug)
        artefact = artefact_for_slug(slug)
        base_section = tag_for_slug(subsection_slug.split('/').first, "section")
        section = tag_for_slug(subsection_slug, "section").merge("parent" => base_section)
        artefact["tags"] << section
        artefact
      end

      def artefact_for_slug_with_related_artefacts(slug, related_artefact_slugs)
        artefact = artefact_for_slug(slug)
        artefact["related"] = related_artefact_slugs.map do |related_slug|
          {
            "title" => titleize_slug(related_slug),
            "id" => "https://contentapi.test.alphagov.co.uk/#{CGI.escape(related_slug)}.json",
            "web_url" => "https://www.test.gov.uk/#{related_slug}",
            "details" => {}
          }
        end
        artefact
      end

      def tag_for_slug(slug, tag_type)
        {
          "title" => titleize_slug(slug.split('/').last),
          "id" => "https://contentapi.test.alphagov.co.uk/tags/#{CGI.escape(slug)}.json",
          "details" => {
            "type" => tag_type
          },
          "content_with_tag" => {
            "id" => "https://contentapi.test.alphagov.co.uk/with_tag.json?tag=#{CGI.escape(slug)}",
            "web_url" => "https://www.test.gov.uk/browse/#{slug}",
          }
        }
      end

      private

        def titleize_slug(slug)
          slug.gsub("-", " ").capitalize
        end

        def response_base
          {
            "_response_info" => {
              "status" => "ok"
            }
          }
        end

        def singular_response_base
          response_base
        end

        def plural_response_base
          response_base.merge(
            {
              "description" => "Tags!",
              "total" => 100,
              "startIndex" => 1,
              "pageSize" => 100,
              "currentPage" => 1,
              "pages" => 1,
              "results" => []
            }
          )
        end
    end
  end
end
