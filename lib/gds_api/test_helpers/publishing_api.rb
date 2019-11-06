require "gds_api/test_helpers/json_client_helper"
require "gds_api/test_helpers/content_item_helpers"
require "gds_api/test_helpers/intent_helpers"
require "json"

module GdsApi
  module TestHelpers
    module PublishingApi
      include ContentItemHelpers
      include IntentHelpers

      PUBLISHING_API_ENDPOINT = Plek.current.find("publishing-api")

      def stub_publishing_api_unreserve_path(base_path, publishing_app = /.*/)
        stub_publishing_api_unreserve_path_with_code(base_path, publishing_app, 200)
      end

      def stub_publishing_api_unreserve_path_not_found(base_path, publishing_app = /.*/)
        stub_publishing_api_unreserve_path_with_code(base_path, publishing_app, 404)
      end

      def stub_publishing_api_unreserve_path_invalid(base_path, publishing_app = /.*/)
        stub_publishing_api_unreserve_path_with_code(base_path, publishing_app, 422)
      end

      def stub_publishing_api_put_intent(base_path, body = intent_for_publishing_api(base_path))
        url = PUBLISHING_API_ENDPOINT + "/publish-intent" + base_path
        body = body.to_json unless body.is_a?(String)
        stub_request(:put, url).with(body: body).to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json; charset=utf-8" })
      end

      def stub_publishing_api_destroy_intent(base_path)
        url = PUBLISHING_API_ENDPOINT + "/publish-intent" + base_path
        stub_request(:delete, url).to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json; charset=utf-8" })
      end

      def stub_default_publishing_api_put_intent
        stub_request(:put, %r{\A#{PUBLISHING_API_ENDPOINT}/publish-intent})
      end

      def assert_publishing_api_put_intent(base_path, attributes_or_matcher = {}, times = 1)
        url = PUBLISHING_API_ENDPOINT + "/publish-intent" + base_path
        assert_publishing_api_put(url, attributes_or_matcher, times)
      end

      def assert_publishing_api_put(url, attributes_or_matcher = {}, times = 1)
        if attributes_or_matcher.is_a?(Hash)
          matcher = attributes_or_matcher.empty? ? nil : request_json_matching(attributes_or_matcher)
        else
          matcher = attributes_or_matcher
        end

        if matcher
          assert_requested(:put, url, times: times, &matcher)
        else
          assert_requested(:put, url, times: times)
        end
      end

      def request_json_matching(required_attributes)
        ->(request) do
          data = JSON.parse(request.body)
          required_attributes.to_a.all? { |key, value| data[key.to_s] == value }
        end
      end

      def request_json_including(required_attributes)
        ->(request) do
          data = JSON.parse(request.body)
          values_match_recursively(required_attributes, data)
        end
      end

      def stub_publishing_api_isnt_available
        stub_request(:any, /#{PUBLISHING_API_ENDPOINT}\/.*/).to_return(status: 503)
      end

      def stub_default_publishing_api_path_reservation
        stub_request(:put, %r[\A#{PUBLISHING_API_ENDPOINT}/paths/]).to_return { |request|
          base_path = request.uri.path.sub(%r{\A/paths/}, "")
          { status: 200, headers: { content_type: "application/json" },
            body: publishing_api_path_data_for(base_path).to_json }
        }
      end

      def stub_publishing_api_has_path_reservation_for(path, publishing_app)
        data = publishing_api_path_data_for(path, "publishing_app" => publishing_app)
        error_data = data.merge("errors" => { "path" => ["is already reserved by the #{publishing_app} application"] })

        stub_request(:put, "#{PUBLISHING_API_ENDPOINT}/paths#{path}").
                  to_return(status: 422, body: error_data.to_json,
                            headers: { content_type: "application/json" })

        stub_request(:put, "#{PUBLISHING_API_ENDPOINT}/paths#{path}").
          with(body: { "publishing_app" => publishing_app }).
          to_return(status: 200,
                    headers: { content_type: "application/json" },
                    body: data.to_json)
      end

      def stub_publishing_api_returns_path_reservation_validation_error_for(path, error_details = nil)
        error_details ||= { "base" => ["computer says no"] }
        error_data = publishing_api_path_data_for(path).merge("errors" => error_details)

        stub_request(:put, "#{PUBLISHING_API_ENDPOINT}/paths#{path}").
          to_return(status: 422, body: error_data.to_json, headers: { content_type: "application/json" })
      end

      # Aliases for DEPRECATED methods
      alias_method :publishing_api_isnt_available, :stub_publishing_api_isnt_available
      alias_method :publishing_api_has_path_reservation_for, :stub_publishing_api_has_path_reservation_for
      alias_method :publishing_api_returns_path_reservation_validation_error_for, :stub_publishing_api_returns_path_reservation_validation_error_for

    private

      def stub_publishing_api_unreserve_path_with_code(base_path, publishing_app, code)
        url = PUBLISHING_API_ENDPOINT + "/paths" + base_path
        body = { publishing_app: publishing_app }
        stub_request(:delete, url).with(body: body).to_return(status: code, body: "{}", headers: { "Content-Type" => "application/json; charset=utf-8" })
      end

      def values_match_recursively(expected_value, actual_value)
        case expected_value
        when Hash
          return false unless actual_value.is_a?(Hash)

          expected_value.all? do |expected_sub_key, expected_sub_value|
            actual_value.has_key?(expected_sub_key.to_s) &&
              values_match_recursively(expected_sub_value, actual_value[expected_sub_key.to_s])
          end
        when Array
          return false unless actual_value.is_a?(Array)
          return false unless actual_value.size == expected_value.size

          expected_value.each.with_index.all? do |expected_sub_value, i|
            values_match_recursively(expected_sub_value, actual_value[i])
          end
        else
          expected_value == actual_value
        end
      end

      def content_item_for_publishing_api(base_path, publishing_app = "publisher")
        content_item_for_base_path(base_path).merge("publishing_app" => publishing_app)
      end

      def intent_for_publishing_api(base_path, publishing_app = "publisher")
        intent_for_base_path(base_path).merge("publishing_app" => publishing_app)
      end

      def publishing_api_path_data_for(path, override_attributes = {})
        now = Time.zone.now.utc.iso8601
        {
          "path" => path,
          "publishing_app" => "foo-publisher",
          "created_at" => now,
          "updated_at" => now,
        }.merge(override_attributes)
      end
    end
  end
end
