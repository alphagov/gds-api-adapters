require 'gds_api/test_helpers/json_client_helper'
require 'gds_api/test_helpers/content_item_helpers'
require 'gds_api/test_helpers/intent_helpers'
require 'json'

module GdsApi
  module TestHelpers
    module PublishingApiV2
      include ContentItemHelpers

      PUBLISHING_API_V2_ENDPOINT = Plek.current.find('publishing-api') + '/v2'

      # stubs a PUT /v2/content/:content_id request with the given content id and request body.
      # if no response_hash is given, a default response as follows is created:
      # {status: 200, body: '{}', headers: {"Content-Type" => "application/json; charset=utf-8"}}
      #
      # if a response is given, then it will be merged with the default response.
      # if the given parameter for the response body is a Hash, it will be converted to JSON.
      #
      # e.g. The following two examples are equivalent:
      #
      # * stub_publishing_api_put_content(my_content_id, my_request_body, { status: 201, body: {version: 33}.to_json })
      # * stub_publishing_api_put_content(my_content_id, my_request_body, { status: 201, body: {version: 33} })
      #
      def stub_publishing_api_put_content(content_id, body, response_hash = {})
        stub_publishing_api_put(content_id, body, '/content', response_hash)
      end

      def stub_publishing_api_patch_links(content_id, body)
        stub_publishing_api_patch(content_id, body, '/links')
      end

      def stub_publishing_api_publish(content_id, body, response_hash = {})
        url = PUBLISHING_API_V2_ENDPOINT + "/content/#{content_id}/publish"
        response = {
          status: 200,
          body: '{}',
          headers: {"Content-Type" => "application/json; charset=utf-8"}
        }.merge(response_hash)
        stub_request(:post, url).with(body: body).to_return(response)
      end

      def stub_publishing_api_unpublish(content_id, params, response_hash = {})
        url = PUBLISHING_API_V2_ENDPOINT + "/content/#{content_id}/unpublish"
        response = {
          status: 200,
          body: '{}',
          headers: {"Content-Type" => "application/json; charset=utf-8"}
        }.merge(response_hash)
        stub_request(:post, url).with(params).to_return(response)
      end

      def stub_publishing_api_discard_draft(content_id)
        url = PUBLISHING_API_V2_ENDPOINT + "/content/#{content_id}/discard-draft"
        stub_request(:post, url).to_return(status: 200, headers: {"Content-Type" => "application/json; charset=utf-8"})
      end

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

      def stub_any_publishing_api_put_content
        stub_request(:put, %r{\A#{PUBLISHING_API_V2_ENDPOINT}/content/})
      end

      def stub_any_publishing_api_patch_links
        stub_request(:patch, %r{\A#{PUBLISHING_API_V2_ENDPOINT}/links/})
      end

      def stub_any_publishing_api_call
        stub_request(:any, %r{\A#{PUBLISHING_API_V2_ENDPOINT}})
      end

      def stub_any_publishing_api_call_to_return_not_found
        stub_request(:any, %r{\A#{PUBLISHING_API_V2_ENDPOINT}})
          .to_return(status: 404, headers: {"Content-Type" => "application/json; charset=utf-8"})
      end

      def publishing_api_isnt_available
        stub_request(:any, /#{PUBLISHING_API_V2_ENDPOINT}\/.*/).to_return(status: 503)
      end

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

      def assert_publishing_api_put_content(content_id, attributes_or_matcher = nil, times = 1)
        url = url_for("content", content_id)
        assert_publishing_api(:put, url, attributes_or_matcher, times)
      end

      def assert_publishing_api_publish(content_id, attributes_or_matcher = nil, times = 1)
        url = PUBLISHING_API_V2_ENDPOINT + "/content/#{content_id}/publish"
        assert_publishing_api(:post, url, attributes_or_matcher, times)
      end

      def assert_publishing_api_patch_links(content_id, attributes_or_matcher = nil, times = 1)
        url = PUBLISHING_API_V2_ENDPOINT + "/links/" + content_id
        assert_publishing_api(:patch, url, attributes_or_matcher, times)
      end

      def assert_publishing_api_discard_draft(content_id, attributes_or_matcher = nil, times = 1)
        url = PUBLISHING_API_V2_ENDPOINT + "/content/#{content_id}/discard-draft"
        assert_publishing_api(:post, url, attributes_or_matcher, times)
      end

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

      def request_json_includes(required_attributes)
        ->(request) do
          data = JSON.parse(request.body)
          deep_stringify_keys(required_attributes).
            to_a.all? { |key, value| data[key] == value }
        end
      end

      def request_json_matches(required_attributes)
        ->(request) do
          data = JSON.parse(request.body)
          deep_stringify_keys(required_attributes) == data
        end
      end

      # Example of use:

      # publishing_api_has_content(
      #   vehicle_recalls_and_faults,   # this is a variable containing an array of content items
      #   document_type: described_class.publishing_api_document_type,   #example of a document_type: "vehicle_recalls_and_faults_alert"
      #   fields: fields,   #example: let(:fields) { %i[base_path content_id public_updated_at title publication_state] }
      #   page: 1,
      #   per_page: 50
      #)
      def publishing_api_has_content(items, params = {})
        url = PUBLISHING_API_V2_ENDPOINT + "/content"
        stub_request(:get, url).with(:query => params).to_return(status: 200, body: { results: items }.to_json, headers: {})
      end

      # This method has been refactored into publishing_api_has_content (above)
      # publishing_api_has_content allows for flexible passing in of arguments, please use instead
      def publishing_api_has_fields_for_document(format, items, fields)
        body = Array(items).map { |item|
          item.with_indifferent_access.slice(*fields)
        }

        query_params = fields.map { |f|
          "&fields%5B%5D=#{f}"
        }

        url = url_for("content?document_type=#{format}#{query_params.join('')}")
        stub_request(:get, url).to_return(:status => 200, :body => { results: body }.to_json, :headers => {})
      end

      def publishing_api_has_linkables(linkables, document_type:)
        url = PUBLISHING_API_V2_ENDPOINT + "/linkables?document_type=#{document_type}"
        stub_request(:get, url).to_return(:status => 200, :body => linkables.to_json, :headers => {})
      end

      def publishing_api_has_item(item)
        item = item.with_indifferent_access
        url = PUBLISHING_API_V2_ENDPOINT + "/content/" + item[:content_id]
        stub_request(:get, url).to_return(status: 200, body: item.to_json, headers: {})
      end

      def publishing_api_does_not_have_item(content_id)
        url = PUBLISHING_API_V2_ENDPOINT + "/content/" + content_id
        stub_request(:get, url).to_return(status: 404, body: resource_not_found(content_id, "content item").to_json, headers: {})
      end

      def publishing_api_has_links(links)
        links = links.with_indifferent_access
        url = PUBLISHING_API_V2_ENDPOINT + "/links/" + links[:content_id]
        stub_request(:get, url).to_return(status: 200, body: links.to_json, headers: {})
      end

      def publishing_api_has_expanded_links(links)
        url = PUBLISHING_API_V2_ENDPOINT + "/expanded-links/" + links[:content_id]
        stub_request(:get, url).to_return(status: 200, body: links.to_json, headers: {})
      end

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

    private

      def stub_publishing_api_put(*args)
        stub_publishing_api_postlike_call(:put, *args)
      end

      def stub_publishing_api_patch(*args)
        stub_publishing_api_postlike_call(:patch, *args)
      end

      def stub_publishing_api_get(*resource_paths, body:, params: {})
        url = url_for(resource_paths)

        stub_request(:get, url)
            .with(:query => params)
            .to_return({
                status: 200,
                body: body.to_json,
                headers: {"Content-Type" => "application/json; charset=utf-8"}
            })
      end

      def stub_publishing_api_postlike_call(method, content_id, body, resource_path, override_response_hash = {})
        response_hash = {status: 200, body: '{}', headers: {"Content-Type" => "application/json; charset=utf-8"}}
        response_hash.merge!(override_response_hash)
        response_hash[:body] = response_hash[:body].to_json if response_hash[:body].is_a?(Hash)
        url = PUBLISHING_API_V2_ENDPOINT + resource_path + "/" + content_id
        stub_request(method, url).with(body: body).to_return(response_hash)
      end

      def deep_stringify_keys(hash)
        deep_transform_keys(hash) { |key| key.to_s }
      end

      def deep_transform_keys(object, &block)
        case object
        when Hash
          object.each_with_object({}) do |(key, value), result|
            result[yield(key)] = deep_transform_keys(value, &block)
          end
        when Array
          object.map{ |item| deep_transform_keys(item, &block) }
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

      def url_for(*resource_paths)
          resource_paths.unshift(PUBLISHING_API_V2_ENDPOINT).join("/")
      end
    end
  end
end
