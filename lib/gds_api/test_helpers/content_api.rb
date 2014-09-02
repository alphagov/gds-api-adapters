require 'gds_api/test_helpers/json_client_helper'
require 'cgi'
require 'gds_api/test_helpers/common_responses'
require 'gds_api/test_helpers/business_support_helper'

module GdsApi
  module TestHelpers
    module ContentApi
      include GdsApi::TestHelpers::CommonResponses
      include GdsApi::TestHelpers::BusinessSupportHelper
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

      def content_api_has_artefacts_in_a_section(slug, artefact_slugs=nil)
        content_api_has_artefacts_with_a_tag("section", slug, artefact_slugs)
      end

      def artefact_for_slug_in_a_section(slug, section_slug)
        artefact_for_slug_with_a_tag("section", slug, section_slug)
      end

      def artefact_for_slug_in_a_subsection(slug, subsection_slug)
        artefact_for_slug_with_a_child_tag("section", slug, subsection_slug)
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

      def content_api_has_tag(tag_type, slug_or_hash, parent_tag_id=nil)
        tag = tag_hash(slug_or_hash, tag_type).merge(parent: parent_tag_id)
        body = tag_result(tag)

        urls = ["#{CONTENT_API_ENDPOINT}/tags/#{CGI.escape(tag_type)}/#{CGI.escape(tag[:slug])}.json"]

        if tag_type == "section"
          urls << "#{CONTENT_API_ENDPOINT}/tags/#{CGI.escape(tag[:slug])}.json"
        end

        urls.each do |url|
          stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
        end
      end

      def content_api_does_not_have_tag(tag_type, slug)
        body = {
          "_response_info" => {
            "status" => "not found"
          }
        }

        urls = ["#{CONTENT_API_ENDPOINT}/tags/#{CGI.escape(tag_type)}/#{CGI.escape(slug)}.json"]

        if tag_type == "section"
          urls << "#{CONTENT_API_ENDPOINT}/tags/#{CGI.escape(slug)}.json"
        end

        urls.each do |url|
          stub_request(:get, url).to_return(status: 404, body: body.to_json, headers: {})
        end
      end

      def content_api_has_draft_and_live_tags(options = {})
        type = options.fetch(:type)
        live_tags = options.fetch(:live).map { |tag| tag_result(tag, type, state: 'live') }
        draft_tags = options.fetch(:draft).map { |tag| tag_result(tag, type, state: 'draft') }

        body = plural_response_base.merge("results" => (live_tags + draft_tags))
        url = "#{CONTENT_API_ENDPOINT}/tags.json?type=#{type}&draft=true"
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})

        body = plural_response_base.merge("results" => live_tags)
        url = "#{CONTENT_API_ENDPOINT}/tags.json?type=#{type}"
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})

        if options[:sort_order]
          body = plural_response_base.merge("results" => (live_tags + draft_tags))
          url = "#{CONTENT_API_ENDPOINT}/tags.json?type=#{type}&draft=true&sort=#{options[:sort_order]}"
          stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})

          body = plural_response_base.merge("results" => live_tags)
          url = "#{CONTENT_API_ENDPOINT}/tags.json?type=#{type}&sort=#{options[:sort_order]}"
          stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
        end
      end

      def content_api_does_not_have_tags(tag_type, slugs)
        body = {
          "_response_info" => {
            "status" => "not found"
          }
        }

        [
          "#{CONTENT_API_ENDPOINT}/tags.json?type=#{tag_type}",
          "#{CONTENT_API_ENDPOINT}/tags.json?draft=true&type=#{tag_type}"
        ].each do |url|
          stub_request(:get, url).to_return(status: 404, body: body.to_json, headers: {})
        end
      end

      def content_api_has_tags(tag_type, slugs_or_tags)
        body = plural_response_base.merge(
          "results" => slugs_or_tags.map { |tag| tag_result(tag, tag_type) }
        )

        [
          "#{CONTENT_API_ENDPOINT}/tags.json?type=#{tag_type}",
          "#{CONTENT_API_ENDPOINT}/tags.json?draft=true&type=#{tag_type}"
        ].each do |url|
          stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
        end
      end

      def content_api_has_sorted_tags(tag_type, sort_order, slugs_or_tags)
        body = plural_response_base.merge(
          "results" => slugs_or_tags.map { |tag| tag_result(tag, tag_type) }
        )

        [
          "#{CONTENT_API_ENDPOINT}/tags.json?sort=#{sort_order}&type=#{tag_type}",
          "#{CONTENT_API_ENDPOINT}/tags.json?draft=true&sort=#{sort_order}&type=#{tag_type}"
        ].each do |url|
          stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
        end
      end

      def content_api_has_child_tags(tag_type, parent_slug_or_hash, child_tag_ids)
        parent_tag = tag_hash(parent_slug_or_hash, tag_type)
        child_tags = child_tag_ids.map { |id|
          tag_hash(id, tag_type).merge(parent: parent_tag)
        }
        body = plural_response_base.merge(
          "results" => child_tags.map { |s| tag_result(s, tag_type) }
        )
        url = "#{CONTENT_API_ENDPOINT}/tags.json?type=#{tag_type}&parent_id=#{CGI.escape(parent_tag[:slug])}"
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end

      def content_api_has_sorted_child_tags(tag_type, parent_slug_or_hash, sort_order, child_tag_ids)
        parent_tag = tag_hash(parent_slug_or_hash, tag_type)
        child_tags = child_tag_ids.map { |id|
          tag_hash(id, tag_type).merge(parent: parent_tag)
        }
        body = plural_response_base.merge(
          "results" => child_tags.map { |s| tag_result(s, tag_type) }
        )

        url = "#{CONTENT_API_ENDPOINT}/tags.json?parent_id=#{CGI.escape(parent_tag[:slug])}&sort=#{sort_order}&type=#{tag_type}"
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end

      def content_api_has_artefacts_with_a_tag(tag_type, slug, artefact_slugs=[])
        body = plural_response_base.merge(
          "results" => artefact_slugs.map do |artefact_slug|
            artefact_for_slug(artefact_slug)
          end
        )

        endpoint = "#{CONTENT_API_ENDPOINT}/with_tag.json"
        resp = { status: 200, body: body.to_json, headers: {} }

        stub_request(:get, endpoint)
          .with(:query => { tag_type => slug })
          .to_return(resp)

        if tag_type == "section"
          stub_request(:get, endpoint)
            .with(:query => { "tag" => slug })
            .to_return(resp)
        end

        sort_orders = ["alphabetical", "curated"]
        sort_orders.each do |order|
          stub_request(:get, endpoint)
            .with(:query => { tag_type => slug, "sort" => order })
            .to_return(resp)

          if tag_type == "section"
            stub_request(:get, endpoint)
              .with(:query => { "tag" => slug, "sort" => order })
              .to_return(resp)
          end
        end
      end

      def content_api_has_sorted_artefacts_with_a_tag(tag_type, slug, sort_order, artefact_slugs=[])
        body = plural_response_base.merge(
          "results" => artefact_slugs.map do |artefact_slug|
            artefact_for_slug(artefact_slug)
          end
        )

        endpoint = "#{CONTENT_API_ENDPOINT}/with_tag.json"
        stub_request(:get, endpoint)
          .with(:query => { tag_type => slug, "sort" => sort_order })
          .to_return(status: 200, body: body.to_json, headers: {})
      end

      def content_api_has_grouped_artefacts_with_a_tag(tag_type, tag_id, group_by, grouped_artefact_slugs={})
        body = plural_response_base.merge(
          "grouped_results" => grouped_artefact_slugs.map {|name,artefact_slugs|
            {
              "name" => name,
              "formats" => [name.downcase],
              "items" => artefact_slugs.map {|artefact_slug|
                artefact_for_slug(artefact_slug)
              }
            }
          }
        )

        endpoint = "#{CONTENT_API_ENDPOINT}/with_tag.json"
        stub_request(:get, endpoint)
          .with(:query => { tag_type => tag_id, "group_by" => group_by })
          .to_return(status: 200, body: body.to_json, headers: {})
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
            "need_ids" => ["100001"],
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

      def artefact_for_slug_with_a_tag(tag_type, slug, tag_id)
        artefact = artefact_for_slug(slug)
        artefact["tags"] << tag_for_slug(tag_id, tag_type)
        artefact
      end

      def artefact_for_slug_with_a_child_tag(tag_type, slug, child_tag_id)
        artefact_for_slug_with_a_child_tags(tag_type, slug, [child_tag_id])
      end

      def artefact_for_slug_with_a_child_tags(tag_type, slug, child_tag_ids)
        artefact = artefact_for_slug(slug)

        child_tag_ids.each do |child_tag_id|
          # for each "part" of the path, we want to reduce across the
          # list and build up a tree of nested tags.
          # This will turn "thing1/thing2" into:
          #   Tag{ thing2, parent: Tag{ thing1 } }

          tag_tree = nil
          child_tag_id.split('/').inject(nil) do |parent_tag, child_tag|
            child_tag = [parent_tag, child_tag].join('/') if parent_tag
            next_level_tag = tag_for_slug(child_tag, tag_type)
            if tag_tree
              # Because tags are nested within one another, this makes
              # the current part the top, and the rest we've seen the
              # ancestors
              tag_tree = next_level_tag.merge("parent" => tag_tree)
            else
              tag_tree = next_level_tag
            end

            # This becomes the parent tag in the next iteration of the block
            child_tag
          end
          artefact["tags"] << tag_tree
        end

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

      def tag_result(slug_or_hash, tag_type = nil, options = {})
        tag = tag_hash(slug_or_hash, tag_type)

        parent = tag_result(tag[:parent]) if tag[:parent]
        pluralized_tag_type = simple_tag_type_pluralizer(tag[:type])

        {
          "id" => "#{CONTENT_API_ENDPOINT}/tags/#{CGI.escape(pluralized_tag_type)}/#{CGI.escape(tag[:slug])}.json",
          "slug" => tag[:slug],
          "web_url" => "http://www.test.gov.uk/browse/#{tag[:slug]}",
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
          },
          "state" => options[:state]
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
        setup_business_support_stubs(CONTENT_API_ENDPOINT, 'business_support_schemes')
      end

      def content_api_has_business_support_scheme(scheme, facets)
        api_has_business_support(scheme, facets)
      end

      def content_api_has_default_business_support_schemes
        empty_results = {
          "_response_info" => {"status" => "ok"},
          "description" => "Business Support Schemes!",
          "total" => 0, "startIndex" => 1, "pageSize" => 0, "currentPage" => 1, "pages" => 1,
          "results" => []
        }

        stub_request(:get, %r{\A#{CONTENT_API_ENDPOINT}/business_support_schemes\.json}).
          to_return(:body => empty_results.to_json)
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
            "need_ids" => [],
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
