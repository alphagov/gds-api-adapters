require 'gds_api/test_helpers/json_client_helper'
require 'cgi'
require 'gds_api/test_helpers/common_responses'

module GdsApi
  module TestHelpers
    module ContentApi
      include GdsApi::TestHelpers::CommonResponses
      # Generally true. If you are initializing the client differently,
      # you could redefine/override the constant or stub directly.
      CONTENT_API_ENDPOINT = Plek.current.find('contentapi')

      # Legacy section test helpers
      #
      # Use of these should be retired in favour of the other test helpers in this
      # module which work with any tag type.

      def content_api_has_root_sections(slugs_or_sections)
        content_api_has_root_tags("section", slugs_or_sections)
      end

      def content_api_has_section(slug_or_hash, parent_slug=nil)
        content_api_has_tag("section", slug_or_hash, parent_slug)
      end

      def content_api_has_subsections(parent_slug_or_hash, subsection_slugs)
        content_api_has_child_tags("section", parent_slug_or_hash, subsection_slugs)
      end


      # Takes an array of slugs, or hashes with section details (including a slug).
      # Will stub out content_api calls for tags of type section to return these sections
      def content_api_has_root_tags(tag_type, slugs_or_tags)
        body = plural_response_base.merge(
          "results" => slugs_or_tags.map { |tag| tag_result(tag, tag_type) }
        )
        urls = ["type=#{tag_type}", "root_sections=true&type=#{tag_type}"].map { |q|
          "#{CONTENT_API_ENDPOINT}/tags.json?#{q}"
        }
        urls.each do |url|
          stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
        end
      end

      def content_api_has_tag(tag_type, slug_or_hash, parent_slug=nil)
        section = tag_hash(slug_or_hash, tag_type).merge(parent: parent_slug)
        body = tag_result(section)

        urls = ["#{CONTENT_API_ENDPOINT}/tags/#{CGI.escape(tag_type)}/#{CGI.escape(section[:slug])}.json"]

        if tag_type == "section"
          urls << "#{CONTENT_API_ENDPOINT}/tags/#{CGI.escape(section[:slug])}.json"
        end

        urls.each do |url|
          stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
        end
      end

      def content_api_has_tags(tag_type, slugs_or_tags)
        body = plural_response_base.merge(
          "results" => slugs_or_tags.map { |tag| tag_result(tag, tag_type) }
        )

        url = "#{CONTENT_API_ENDPOINT}/tags.json?type=#{tag_type}"
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end

      def content_api_has_child_tags(tag_type, parent_slug_or_hash, subsection_slugs)
        parent_section = tag_hash(parent_slug_or_hash, tag_type)
        subsections = subsection_slugs.map { |s|
          tag_hash(s, tag_type).merge(parent: parent_section)
        }
        body = plural_response_base.merge(
          "results" => subsections.map { |s| tag_result(s, tag_type) }
        )
        url = "#{CONTENT_API_ENDPOINT}/tags.json?type=#{tag_type}&parent_id=#{CGI.escape(parent_section[:slug])}"
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end

      def content_api_has_artefacts_in_a_section(slug, artefact_slugs=[])
        body = plural_response_base.merge(
          "results" => artefact_slugs.map do |artefact_slug|
            artefact_for_slug(artefact_slug)
          end
        )
        sort_orders = ["alphabetical", "curated"]
        sort_orders.each do |order|
          url = "#{CONTENT_API_ENDPOINT}/with_tag.json?sort=#{order}&tag=#{CGI.escape(slug)}"
          stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
        end
      end

      def content_api_has_an_artefact(slug, body = artefact_for_slug(slug))
        ArtefactStub.new(slug).with_response_body(body).stub
      end

      def content_api_has_unpublished_artefact(slug, edition, body = artefact_for_slug(slug))
        ArtefactStub.new(slug)
            .with_response_body(body)
            .with_query_parameters(edition: edition)
            .stub
      end

      def content_api_has_an_artefact_with_snac_code(slug, snac, body = artefact_for_slug(slug))
        ArtefactStub.new(slug)
            .with_response_body(body)
            .with_query_parameters(snac: snac)
            .stub
      end

      def content_api_does_not_have_an_artefact(slug)
        body = {
          "_response_info" => {
            "status" => "not found"
          }
        }
        ArtefactStub.new(slug)
            .with_response_body(body)
            .with_response_status(404)
            .stub
      end

      def content_api_has_an_archived_artefact(slug)
        body = {
          "_response_info" => {
            "status" => "gone",
            "status_message" => "This item is no longer available"
          }
        }
        ArtefactStub.new(slug)
            .with_response_body(body)
            .with_response_status(410)
            .stub
      end

      # Stub requests, and then dynamically generate a response based on the slug in the request
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
          "id" => "#{CONTENT_API_ENDPOINT}/#{CGI.escape(slug)}.json",
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
            "id" => "#{CONTENT_API_ENDPOINT}/#{CGI.escape(related_slug)}.json",
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

        tag_result(slug: slug, type: tag_type, parent: parent)
      end

      # Construct a tag hash suitable for passing into tag_result
      def tag_hash(slug_or_hash, tag_type = "section")
        if slug_or_hash.is_a?(Hash)
          slug_or_hash
        else
          { slug: slug_or_hash, type: tag_type }
        end
      end

      def tag_result(slug_or_hash, tag_type = nil)
        tag = tag_hash(slug_or_hash, tag_type)

        parent = tag_result(tag[:parent]) if tag[:parent]
        pluralized_tag_type = simple_tag_type_pluralizer(tag[:type])

        {
          "id" => "#{CONTENT_API_ENDPOINT}/tags/#{CGI.escape(pluralized_tag_type)}/#{CGI.escape(tag[:slug])}.json",
          "web_url" => nil,
          "title" => tag[:title] || titleize_slug(tag[:slug].split("/").last),
          "details" => {
            "type" => tag[:type],
            "description" => tag[:description] || "#{tag[:slug]} description",
            "short_description" => tag[:short_description] || "#{tag[:slug]} short description"
          },
          "parent" => parent,
          "content_with_tag" => {
            "id" => "#{CONTENT_API_ENDPOINT}/with_tag.json?tag=#{CGI.escape(tag[:slug])}",
            "web_url" => "http://www.test.gov.uk/browse/#{tag[:slug]}"
          }
        }
      end

      # This is a nasty hack to get around the pluralized slugs in tag paths
      # without having to require ActiveSupport
      #
      def simple_tag_type_pluralizer(s)
        case s
        when /o\Z/ then s.sub(/o\Z/, "es")
        when /y\Z/ then s.sub(/y\Z/, "ies")
        when /ss\Z/ then s.sub(/ss\Z/, "sses")
        else
          "#{s}s"
        end
      end

      def setup_content_api_business_support_schemes_stubs
        @stubbed_content_api_business_support_schemes = []
        stub_request(:get, %r{\A#{CONTENT_API_ENDPOINT}/business_support_schemes\.json}).to_return do |request|
          if request.uri.query_values and request.uri.query_values["identifiers"]
            ids = request.uri.query_values["identifiers"].split(',')
            results = @stubbed_content_api_business_support_schemes.select {|bs| ids.include? bs["identifier"] }
          else
            results = []
          end
          {:body => plural_response_base.merge("results" => results, "total" => results.size).to_json}
        end
      end

      def content_api_has_business_support_scheme(scheme)
        raise "Need an identifier" if scheme["identifier"].nil?
        @stubbed_content_api_business_support_schemes << scheme
      end

      def content_api_licence_hash(licence_identifier, options = {})
        details = {
          title: "Publisher title",
          slug: 'licence-slug',
          licence_short_description: "Short description of licence"
        }
        details.merge!(options)

        {
          "title" => details[:title],
          "id" => "http://example.org/#{details[:slug]}.json",
          "web_url" =>  "http://www.test.gov.uk/#{details[:slug]}",
          "format" => "licence",
          "details" => {
            "need_id" => nil,
            "business_proposition" => false,
            "alternative_title" => nil,
            "overview" => nil,
            "will_continue_on" => nil,
            "continuation_link" => nil,
            "licence_identifier" => licence_identifier,
            "licence_short_description" => details[:licence_short_description],
            "licence_overview" => nil,
            "updated_at" => "2012-10-06T12:00:05+01:00"
          },
          "tags" => [],
          "related" => []
        }
      end

      def setup_content_api_licences_stubs
        @stubbed_content_api_licences = []
        stub_request(:get, %r{\A#{CONTENT_API_ENDPOINT}/licences}).to_return do |request|
          if request.uri.query_values and request.uri.query_values["ids"]
            ids = request.uri.query_values["ids"].split(',')
            valid_licences = @stubbed_content_api_licences.select { |l| ids.include? l[:licence_identifier] }
            {
              :body => {
                'results' => valid_licences.map { |licence|
                  content_api_licence_hash(licence[:licence_identifier], licence)
                }
              }.to_json
            }
          else
            {:body => {'results' => []}.to_json}
          end
        end
      end

      def content_api_has_licence(details)
        raise "Need a licence identifier" if details[:licence_identifier].nil?
        @stubbed_content_api_licences << details
      end

      def content_api_has_artefacts_for_need_id(need_id, artefacts)
        url = "#{CONTENT_API_ENDPOINT}/for_need/#{CGI.escape(need_id.to_s)}.json"
        body = plural_response_base.merge(
          'results' => artefacts
        )

        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: [])
      end
    end
  end
end

# This has to be after the definition of TestHelpers::ContentApi, otherwise, this doesn't pick up
# the include of TestHelpers::CommonResponses
require_relative 'content_api/artefact_stub'
