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
        ["#{CONTENT_API_ENDPOINT}/tags.json?type=section", "#{CONTENT_API_ENDPOINT}/tags.json?root_sections=true&type=section"].each do |url|
          stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
        end
      end

      def content_api_has_section(slug, parent_slug=nil)
        body = tag_for_slug(slug, "section", parent_slug)
        url = "#{CONTENT_API_ENDPOINT}/tags/#{CGI.escape(slug)}.json"
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end

      def content_api_has_artefacts_in_a_section(slug, artefact_slugs=[])
        body = plural_response_base.merge(
          "results" => artefact_slugs.map do |artefact_slug|
            artefact_for_slug(artefact_slug)
          end
        )
        url = "https://contentapi.test.alphagov.co.uk/with_tag.json?sort=alphabetical&tag=#{CGI.escape(slug)}"
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end

      def content_api_has_subsections(parent_slug, subsection_slugs)
        parent_section = tag_for_slug(parent_slug, "section")
        body = plural_response_base.merge(
          "results" => subsection_slugs.map do |slug|
            {
              "id" => "http://contentapi.test.gov.uk/tags/#{CGI.escape(slug)}.json",
              "web_url" => nil,
              "title" => titleize_slug(slug),
              "details" => {
                "type" => "section",
                "description" => "#{slug} description"
              },
              "parent" => parent_section,
              "content_with_tag" => {
                "id" => "http://contentapi.test.gov.uk/with_tag.json?tag=#{CGI.escape(slug)}",
                "web_url" => "http://www.test.gov.uk/browse/#{slug}"
              }
            }
          end
        )
        url = "#{CONTENT_API_ENDPOINT}/tags.json?type=section&parent_id=#{CGI.escape(parent_slug)}"
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end

      def content_api_has_an_artefact(slug, body = artefact_for_slug(slug))
        url = "#{CONTENT_API_ENDPOINT}/#{slug}.json"
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end

      def content_api_has_unpublished_artefact(slug, edition, body = artefact_for_slug(slug))
        url = "#{CONTENT_API_ENDPOINT}/#{slug}.json?edition=#{edition}"
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end

      def content_api_has_an_artefact_with_snac_code(slug, snac, body = artefact_for_slug(slug))
        url = "#{CONTENT_API_ENDPOINT}/#{slug}.json?snac=#{snac}"
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

      def content_api_has_an_archived_artefact(slug)
        body = {
          "_response_info" => {
            "status" => "gone",
            "status_message" => "This item is no longer available"
          }
        }
        url = "#{CONTENT_API_ENDPOINT}/#{slug}.json"
        stub_request(:get, url).to_return(status: 410, body: body.to_json, headers: {})
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
          "format" => "guide",
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

        # for each "part" of the path, we want to reduce across the
        # list and build up a tree of nested tags.
        # This will turn "thing1/thing2" into:
        #   Tag{ thing2, parent: Tag{ thing1 } }

        tag_tree = nil
        subsection_slug.split('/').inject(nil) do |last_section, subsection|
          subsection = [last_section, subsection].join('/') if last_section
          section = tag_for_slug(subsection, "section")
          if tag_tree
            # Because tags are nested within one another, this makes
            # the current part the top, and the rest we've seen the
            # ancestors
            tag_tree = section.merge("parent" => tag_tree)
          else
            tag_tree = section
          end
          subsection
        end
        artefact["tags"] << tag_tree
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

      def tag_for_slug(slug, tag_type, parent_slug=nil)
        parent = if parent_slug
          tag_for_slug(parent_slug, tag_type)
        end
        {
          "title" => titleize_slug(slug.split('/').last),
          "id" => "https://contentapi.test.alphagov.co.uk/tags/#{CGI.escape(slug)}.json",
          "details" => {
            "type" => tag_type
          },
          "content_with_tag" => {
            "id" => "https://contentapi.test.alphagov.co.uk/with_tag.json?tag=#{CGI.escape(slug)}",
            "web_url" => "https://www.test.gov.uk/browse/#{slug}",
          },
          "parent" => parent
        }
      end

      def setup_content_api_business_support_schemes_stubs
        @stubbed_content_api_business_support_schemes = []
        stub_request(:get, %r{\A#{CONTENT_API_ENDPOINT}/business_support_schemes\.json}).to_return do |request|
          if request.uri.query_values and request.uri.query_values["identifiers"]
            ids = request.uri.query_values["identifiers"].split(',')
            results = @stubbed_content_api_business_support_schemes.select {|bs| ids.include? bs["details"]["business_support_identifier"] }
          else
            results = []
          end
          {:body => plural_response_base.merge("results" => results, "total" => results.size).to_json}
        end
      end

      def content_api_has_business_support_scheme(scheme)
        raise "Need a licence identifier" if scheme["details"]["business_support_identifier"].nil?
        @stubbed_content_api_business_support_schemes << scheme
      end

      def setup_content_api_licences_stubs
        @stubbed_content_api_licences = []
        stub_request(:get, %r{\A#{CONTENT_API_ENDPOINT}/licences}).to_return do |request|
          if request.uri.query_values and request.uri.query_values["ids"]
            ids = request.uri.query_values["ids"].split(',')
            {:body => @stubbed_content_api_licences.select {|l| ids.include? l[:licence_identifier] }.to_json}
          else
            {:body => [].to_json}
          end
        end
      end

      def content_api_has_licence(details)
        raise "Need a licence identifier" if details[:licence_identifier].nil?
        @stubbed_content_api_licences << details
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
