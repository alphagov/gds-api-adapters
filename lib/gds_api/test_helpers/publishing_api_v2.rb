require 'gds_api/test_helpers/json_client_helper'
require 'gds_api/test_helpers/content_item_helpers'
require 'gds_api/test_helpers/intent_helpers'
require 'json'

module GdsApi
  module TestHelpers
    # @api documented
    module PublishingApiV2
      include ContentItemHelpers

      PUBLISHING_API_V2_ENDPOINT = Plek.current.find('publishing-api') + '/v2'

      # Stub a PUT /v2/content/:content_id request with the given content id and request body.
      # if no response_hash is given, a default response as follows is created:
      # {status: 200, body: '{}', headers: {"Content-Type" => "application/json; charset=utf-8"}}
      #
      # if a response is given, then it will be merged with the default response.
      # if the given parameter for the response body is a Hash, it will be converted to JSON.
      #
      # The following two examples are equivalent:
      # @example
      #   stub_publishing_api_put_content(my_content_id, my_request_body, { status: 201, body: {version: 33}.to_json })
      #
      # @example
      #   stub_publishing_api_put_content(my_content_id, my_request_body, { status: 201, body: {version: 33} })
      #
      # @param content_id [UUID]
      # @param body  [String]
      # @param response_hash [Hash]
      def stub_publishing_api_put_content(content_id, body, response_hash = {})
        stub_publishing_api_put(content_id, body, '/content', response_hash)
      end

      # Stub a PATCH /v2/links/:content_id request
      #
      # @param content_id [UUID]
      # @param body  [String]
      def stub_publishing_api_patch_links(content_id, body)
        stub_publishing_api_patch(content_id, body, '/links')
      end

      # Stub a POST /v2/content/:content_id/publish request
      #
      # @param content_id [UUID]
      # @param body  [String]
      # @param response_hash [Hash]
      def stub_publishing_api_publish(content_id, body, response_hash = {})
        url = PUBLISHING_API_V2_ENDPOINT + "/content/#{content_id}/publish"
        response = {
          status: 200,
          body: '{}',
          headers: { "Content-Type" => "application/json; charset=utf-8" }
        }.merge(response_hash)
        stub_request(:post, url).with(body: body).to_return(response)
      end

      # Stub a POST /v2/content/:content_id/unpublish request
      #
      # @param content_id [UUID]
      # @param params [Hash]
      # @param body  [String]
      def stub_publishing_api_unpublish(content_id, params, response_hash = {})
        url = PUBLISHING_API_V2_ENDPOINT + "/content/#{content_id}/unpublish"
        response = {
          status: 200,
          body: '{}',
          headers: { "Content-Type" => "application/json; charset=utf-8" }
        }.merge(response_hash)
        stub_request(:post, url).with(params).to_return(response)
      end

      # Stub a POST /v2/content/:content_id/discard-draft request
      #
      # @param content_id [UUID]
      def stub_publishing_api_discard_draft(content_id)
        url = PUBLISHING_API_V2_ENDPOINT + "/content/#{content_id}/discard-draft"
        stub_request(:post, url).to_return(status: 200, headers: { "Content-Type" => "application/json; charset=utf-8" })
      end

      # Stub requests issued when publishing a new draft.
      # - PUT /v2/content/:content_id
      # - POST /v2/content/:content_id/publish
      # - PATCH /v2/links/:content_id
      #
      # @param body  [String]
      # @param content_id [UUID]
      # @param publish_body [Hash]
      def stub_publishing_api_put_content_links_and_publish(body, content_id = nil, publish_body = nil)
        content_id ||= body[:content_id]
        if publish_body.nil?
          publish_body = { update_type: body.fetch(:update_type) }
          publish_body[:locale] = body[:locale] if body[:locale]
        end
        stubs = []
        stubs << stub_publishing_api_put_content(content_id, body.except(:links))
        stubs << stub_publishing_api_patch_links(content_id, body.slice(:links)) unless body.slice(:links).empty?
        stubs << stub_publishing_api_publish(content_id, publish_body)
        stubs
      end

      # Stub any PUT /v2/content/* request
      def stub_any_publishing_api_put_content
        stub_request(:put, %r{\A#{PUBLISHING_API_V2_ENDPOINT}/content/})
      end

      # Stub any PATCH /v2/links/* request
      def stub_any_publishing_api_patch_links
        stub_request(:patch, %r{\A#{PUBLISHING_API_V2_ENDPOINT}/links/})
      end

      # Stub any POST /v2/content/*/publish request
      def stub_any_publishing_api_publish
        stub_request(:post, %r{\A#{PUBLISHING_API_V2_ENDPOINT}/content/.*/publish})
      end

      # Stub any POST /v2/content/*/unpublish request
      def stub_any_publishing_api_unpublish
        stub_request(:post, %r{\A#{PUBLISHING_API_V2_ENDPOINT}/content/.*/unpublish})
      end

      # Stub any POST /v2/content/*/discard-draft request
      def stub_any_publishing_api_discard_draft
        stub_request(:post, %r{\A#{PUBLISHING_API_V2_ENDPOINT}/content/.*/discard-draft})
      end

      # Stub any version 2 request to the publishing API
      def stub_any_publishing_api_call
        stub_request(:any, %r{\A#{PUBLISHING_API_V2_ENDPOINT}})
      end

      # Stub any version 2 request to the publishing API to return a 404 response
      def stub_any_publishing_api_call_to_return_not_found
        stub_request(:any, %r{\A#{PUBLISHING_API_V2_ENDPOINT}})
          .to_return(status: 404, headers: { "Content-Type" => "application/json; charset=utf-8" })
      end

      # Stub any version 2 request to the publishing API to return a 503 response
      def publishing_api_isnt_available
        stub_request(:any, /#{PUBLISHING_API_V2_ENDPOINT}\/.*/).to_return(status: 503)
      end

      # Assert that a draft was saved and published, and links were updated.
      # - PUT /v2/content/:content_id
      # - POST /v2/content/:content_id/publish
      # - PATCH /v2/links/:content_id
      #
      # @param body  [String]
      # @param content_id [UUID]
      # @param publish_body [Hash]
      def assert_publishing_api_put_content_links_and_publish(body, content_id = nil, publish_body = nil)
        content_id ||= body[:content_id]
        if publish_body.nil?
          publish_body = { update_type: body.fetch(:update_type) }
          publish_body[:locale] = body[:locale] if body[:locale]
        end
        assert_publishing_api_put_content(content_id, body.except(:links))
        assert_publishing_api_patch_links(content_id, body.slice(:links)) unless body.slice(:links).empty?
        assert_publishing_api_publish(content_id, publish_body)
      end

      # Assert that content was saved (PUT /v2/content/:content_id)
      #
      # @param content_id [UUID]
      # @param attributes_or_matcher [Object]
      # @param times [Integer]
      def assert_publishing_api_put_content(content_id, attributes_or_matcher = nil, times = 1)
        url = PUBLISHING_API_V2_ENDPOINT + "/content/" + content_id
        assert_publishing_api(:put, url, attributes_or_matcher, times)
      end

      # Assert that content was published (POST /v2/content/:content_id/publish)
      #
      # @param content_id [UUID]
      # @param attributes_or_matcher [Object]
      # @param times [Integer]
      def assert_publishing_api_publish(content_id, attributes_or_matcher = nil, times = 1)
        url = PUBLISHING_API_V2_ENDPOINT + "/content/#{content_id}/publish"
        assert_publishing_api(:post, url, attributes_or_matcher, times)
      end

      # Assert that content was unpublished (POST /v2/content/:content_id/unpublish)
      #
      # @param content_id [UUID]
      # @param attributes_or_matcher [Object]
      # @param times [Integer]
      def assert_publishing_api_unpublish(content_id, attributes_or_matcher = nil, times = 1)
        url = PUBLISHING_API_V2_ENDPOINT + "/content/#{content_id}/unpublish"
        assert_publishing_api(:post, url, attributes_or_matcher, times)
      end

      # Assert that links were updated (PATCH /v2/links/:content_id)
      #
      # @param content_id [UUID]
      # @param attributes_or_matcher [Object]
      # @param times [Integer]
      def assert_publishing_api_patch_links(content_id, attributes_or_matcher = nil, times = 1)
        url = PUBLISHING_API_V2_ENDPOINT + "/links/" + content_id
        assert_publishing_api(:patch, url, attributes_or_matcher, times)
      end

      # Assert that a draft was discarded (POST /v2/content/:content_id/discard-draft)
      #
      # @param content_id [UUID]
      # @param attributes_or_matcher [Object]
      # @param times [Integer]
      def assert_publishing_api_discard_draft(content_id, attributes_or_matcher = nil, times = 1)
        url = PUBLISHING_API_V2_ENDPOINT + "/content/#{content_id}/discard-draft"
        assert_publishing_api(:post, url, attributes_or_matcher, times)
      end

      # Assert that a request was made to the publishing API
      #
      # @param verb [String]
      # @param url [String]
      # @param attributes_or_matcher [Object]
      # @param times [Integer]
      def assert_publishing_api(verb, url, attributes_or_matcher = nil, times = 1)
        if attributes_or_matcher.is_a?(Hash)
          matcher = request_json_matches(attributes_or_matcher)
        else
          matcher = attributes_or_matcher
        end

        if matcher
          assert_requested(verb, url, times: times, &matcher)
        else
          assert_requested(verb, url, times: times)
        end
      end

      # Get a request matcher that checks if a JSON request includes a set of attributes
      def request_json_includes(required_attributes)
        ->(request) do
          data = JSON.parse(request.body)
          deep_stringify_keys(required_attributes).
            to_a.all? { |key, value| data[key] == value }
        end
      end

      # Get a request matcher that checks if a JSON request matches a hash
      def request_json_matches(required_attributes)
        ->(request) do
          data = JSON.parse(request.body)
          deep_stringify_keys(required_attributes) == data
        end
      end

      # Stub GET /v2/content/ to return a set of content items
      #
      # @example
      #
      #   publishing_api_has_content(
      #     vehicle_recalls_and_faults,   # this is a variable containing an array of content items
      #     document_type: described_class.publishing_api_document_type,   #example of a document_type: "vehicle_recalls_and_faults_alert"
      #     fields: fields,   #example: let(:fields) { %i[base_path content_id public_updated_at title publication_state] }
      #     page: 1,
      #     per_page: 50
      #   )
      # @param items [Array]
      # @param params [Hash]
      def publishing_api_has_content(items, params = {})
        url = PUBLISHING_API_V2_ENDPOINT + "/content"

        if params.respond_to? :fetch
          per_page = params.fetch(:per_page, 50)
          page = params.fetch(:page, 1)
        else
          per_page = 50
          page = 1
        end

        start_position = (page - 1) * per_page
        page_items = items.slice(start_position, per_page) || []

        number_of_pages =
          if items.count < per_page
            1
          else
            (items.count / per_page.to_f).ceil
          end

        body = {
          results: page_items,
          total: items.count,
          pages: number_of_pages,
          current_page: page
        }

        stub_request(:get, url)
          .with(query: params)
          .to_return(status: 200, body: body.to_json, headers: {})
      end

      # This method has been refactored into publishing_api_has_content (above)
      # publishing_api_has_content allows for flexible passing in of arguments, please use instead
      def publishing_api_has_fields_for_document(document_type, items, fields)
        body = Array(items).map { |item|
          deep_stringify_keys(item).slice(*fields)
        }

        query_params = fields.map { |f|
          "&fields%5B%5D=#{f}"
        }

        url = PUBLISHING_API_V2_ENDPOINT + "/content?document_type=#{document_type}#{query_params.join('')}"

        stub_request(:get, url).to_return(status: 200, body: { results: body }.to_json, headers: {})
      end

      # Stub GET /v2/linkables to return a set of content items with a specific document type
      #
      # @param linkables [Array]
      def publishing_api_has_linkables(linkables, document_type:)
        url = PUBLISHING_API_V2_ENDPOINT + "/linkables?document_type=#{document_type}"
        stub_request(:get, url).to_return(status: 200, body: linkables.to_json, headers: {})
      end

      # Stub GET /v2/content/:content_id to return a specific content item hash
      #
      # @param item [Hash]
      def publishing_api_has_item(item, params = {})
        item = deep_transform_keys(item, &:to_sym)
        url = PUBLISHING_API_V2_ENDPOINT + "/content/" + item[:content_id]
        stub_request(:get, url)
          .with(query: hash_including(params))
          .to_return(status: 200, body: item.to_json, headers: {})
      end

      # Stub GET /v2/content/:content_id to progress through a series of responses.
      #
      # @param items [Array]
      def publishing_api_has_item_in_sequence(content_id, items)
        items = items.each { |item| deep_transform_keys(item, &:to_sym) }
        url = PUBLISHING_API_V2_ENDPOINT + "/content/" + content_id
        calls = -1

        stub_request(:get, url).to_return do |_request|
          calls += 1
          item = items[calls] || items.last

          { status: 200, body: item.to_json, headers: {} }
        end
      end

      # Stub GET /v2/content/:content_id to return a 404 response
      #
      # @param content_id [UUID]
      def publishing_api_does_not_have_item(content_id)
        url = PUBLISHING_API_V2_ENDPOINT + "/content/" + content_id
        stub_request(:get, url).to_return(status: 404, body: resource_not_found(content_id, "content item").to_json, headers: {})
      end

      # Stub a request to links endpoint
      #
      # @param [Hash] links the structure of the links hash
      #
      # @example
      #
      #  publishing_api_has_links(
      #    {
      #      "content_id" => "64aadc14-9bca-40d9-abb6-4f21f9792a05",
      #      "links" => {
      #        "mainstream_browse_pages" => ["df2e7a3e-2078-45de-a75a-fd37d027427e"],
      #        "parent" => ["df2e7a3e-2078-45de-a75a-fd37d027427e"],
      #        "organisations" => ["569a9ee5-c195-4b7f-b9dc-edc17a09113f", "5c54ae52-341b-499e-a6dd-67f04633b8cf"]
      #      },
      #      "version" => 6
      #    }
      #  )
      #
      # @example
      #
      #   Services.publishing_api.get_links("64aadc14-9bca-40d9-abb6-4f21f9792a05")
      #   => {
      #        "content_id" => "64aadc14-9bca-40d9-abb6-4f21f9792a05",
      #        "links" => {
      #          "mainstream_browse_pages" => ["df2e7a3e-2078-45de-a75a-fd37d027427e"],
      #          "parent" => ["df2e7a3e-2078-45de-a75a-fd37d027427e"],
      #          "organisations" => ["569a9ee5-c195-4b7f-b9dc-edc17a09113f", "5c54ae52-341b-499e-a6dd-67f04633b8cf"]
      #        },
      #        "version" => 6
      #      }
      def publishing_api_has_links(links)
        links = deep_transform_keys(links, &:to_sym)
        url = PUBLISHING_API_V2_ENDPOINT + "/links/" + links[:content_id]
        stub_request(:get, url).to_return(status: 200, body: links.to_json, headers: {})
      end

      # Stub a request to the expanded links endpoint
      #
      # @param [Hash] links the structure of the links hash
      #
      # @example
      #   publishing_api_has_expanded_links(
      #     {
      #       "content_id" => "64aadc14-9bca-40d9-abb4-4f21f9792a05",
      #       "expanded_links" => {
      #         "mainstream_browse_pages" => [
      #           {
      #             "content_id" => "df2e7a3e-2078-45de-a76a-fd37d027427a",
      #             "base_path" => "/a/base/path",
      #             "document_type" => "mainstream_browse_page",
      #             "locale" => "en",
      #             "links" => {},
      #             # ...
      #           }
      #         ],
      #         "parent" => [
      #           {
      #             "content_id" => "df2e7a3e-2028-45de-a75a-fd37d027427e",
      #             "document_type" => "mainstream_browse_page",
      #             # ...
      #           },
      #         ]
      #       }
      #     }
      #   )
      #
      # @example
      #   Services.publishing_api.expanded_links("64aadc14-9bca-40d9-abb4-4f21f9792a05")
      #   =>  {
      #         "content_id" => "64aadc14-9bca-40d9-abb4-4f21f9792a05",
      #         "expanded_links" => {
      #           "mainstream_browse_pages" => [
      #             {
      #               "content_id" => "df2e7a3e-2078-45de-a76a-fd37d027427a",
      #               "base_path" => "/a/base/path",
      #               "document_type" => "mainstream_browse_page",
      #               "locale" => "en",
      #               "links" => {},
      #               ...
      #             }
      #           ],
      #           "parent" => [
      #             {
      #               "content_id" => "df2e7a3e-2028-45de-a75a-fd37d027427e",
      #               "document_type" => "mainstream_browse_page",
      #               ...
      #             },
      #           ]
      #         }
      #       }
      def publishing_api_has_expanded_links(links, with_drafts: true)
        links = deep_transform_keys(links, &:to_sym)
        query = with_drafts ? "" : "?with_drafts=false"
        url = PUBLISHING_API_V2_ENDPOINT + "/expanded-links/" + links[:content_id] + query
        stub_request(:get, url).to_return(status: 200, body: links.to_json, headers: {})
      end

      # Stub a request to get links for content ids
      #
      # @param [Hash] links the links for each content id
      #
      # @example
      #   publishing_api_has_links_for_content_ids(
      #     { "2878337b-bed9-4e7f-85b6-10ed2cbcd504" => {
      #         "links" => { "taxons" => ["eb6965c7-3056-45d0-ae50-2f0a5e2e0854"] }
      #       },
      #       "eec13cea-219d-4896-9c97-60114da23559" => {
      #         "links" => {}
      #       }
      #     }
      #   )
      #
      # @example
      #   Services.publishing_api.get_links_for_content_ids(["2878337b-bed9-4e7f-85b6-10ed2cbcd504"])
      #   =>  {
      #         "2878337b-bed9-4e7f-85b6-10ed2cbcd504" => {
      #           "links" => [
      #             "eb6965c7-3056-45d0-ae50-2f0a5e2e0854"
      #           ]
      #         }
      #       }
      def publishing_api_has_links_for_content_ids(links)
        url = PUBLISHING_API_V2_ENDPOINT + "/links/by-content-id"
        stub_request(:post, url).with(body: { content_ids: links.keys }).to_return(status: 200, body: links.to_json, headers: {})
      end

      # Stub GET /v2/links/:content_id to return a 404 response
      #
      # @param content_id [UUID]
      def publishing_api_does_not_have_links(content_id)
        url = PUBLISHING_API_V2_ENDPOINT + "/links/" + content_id
        stub_request(:get, url).to_return(status: 404, body: resource_not_found(content_id, "link set").to_json, headers: {})
      end

      # Stub calls to the lookups endpoint
      #
      # @param lookup_hash [Hash] Hash with base_path as key, content_id as value.
      #
      # @example
      #
      #   publishing_api_has_lookups({
      #     "/foo" => "51ac4247-fd92-470a-a207-6b852a97f2db",
      #     "/bar" => "261bd281-f16c-48d5-82d2-9544019ad9ca"
      #   })
      #
      def publishing_api_has_lookups(lookup_hash)
        url = Plek.current.find('publishing-api') + '/lookup-by-base-path'
        stub_request(:post, url).to_return(body: lookup_hash.to_json)
      end

      #
      # Stub calls to the get linked items endpoint
      #
      # @param items [Array] The linked items we wish to return
      # @param params [Hash] A hash of parameters
      #
      # @example
      #
      #   publishing_api_has_linked_items(
      #     [ item_1, item_2 ],
      #     {
      #       content_id: "51ac4247-fd92-470a-a207-6b852a97f2db",
      #       link_type: "taxons",
      #       fields: ["title", "description", "base_path"]
      #     }
      #   )
      #
      def publishing_api_has_linked_items(items, params = {})
        content_id = params.fetch(:content_id)
        link_type = params.fetch(:link_type)
        fields = params.fetch(:fields, %w(base_path content_id document_type title))

        url = Plek.current.find('publishing-api') + "/v2/linked/#{content_id}"

        request_parmeters = {
          "fields" => fields,
          "link_type" => link_type,
        }

        stub_request(:get, url)
          .with(query: request_parmeters)
          .and_return(
            body: items.to_json,
            status: 200
          )
      end

      # Stub GET /v2/editions to return a set of editions
      #
      # @example
      #
      #   publishing_api_get_editions(
      #     vehicle_recalls_and_faults,   # this is a variable containing an array of editions
      #     fields: fields,   #example: let(:fields) { %i[base_path content_id public_updated_at title publication_state] }
      #     per_page: 50
      #   )
      # @param items [Array]
      # @param params [Hash]
      def publishing_api_get_editions(editions, params = {})
        url = PUBLISHING_API_V2_ENDPOINT + "/editions"

        results = editions.map do |edition|
          next edition unless params[:fields]
          edition.select { |k| params[:fields].include?(k) }
        end

        per_page = (params[:per_page] || 100).to_i
        results = results.take(per_page)

        body = {
          results: results,
          links: [
            { rel: "self", href: "#{PUBLISHING_API_V2_ENDPOINT}/editions" },
          ],
        }

        stub_request(:get, url)
          .with(query: params)
          .to_return(status: 200, body: body.to_json, headers: {})
      end

    private

      def stub_publishing_api_put(*args)
        stub_publishing_api_postlike_call(:put, *args)
      end

      def stub_publishing_api_patch(*args)
        stub_publishing_api_postlike_call(:patch, *args)
      end

      def stub_publishing_api_postlike_call(method, content_id, body, resource_path, override_response_hash = {})
        response_hash = { status: 200, body: '{}', headers: { "Content-Type" => "application/json; charset=utf-8" } }
        response_hash.merge!(override_response_hash)
        response_hash[:body] = response_hash[:body].to_json if response_hash[:body].is_a?(Hash)
        url = PUBLISHING_API_V2_ENDPOINT + resource_path + "/" + content_id
        stub_request(method, url).with(body: body).to_return(response_hash)
      end

      def deep_stringify_keys(hash)
        deep_transform_keys(hash, &:to_s)
      end

      def deep_transform_keys(object, &block)
        case object
        when Hash
          object.each_with_object({}) do |(key, value), result|
            result[yield(key)] = deep_transform_keys(value, &block)
          end
        when Array
          object.map { |item| deep_transform_keys(item, &block) }
        else
          object
        end
      end

      def resource_not_found(content_id, type)
        {
          error: {
            code: 404,
            message: "Could not find #{type} with content_id: #{content_id}",
          }
        }
      end
    end
  end
end
