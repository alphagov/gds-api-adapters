require 'gds_api/test_helpers/json_client_helper'
require 'gds_api/test_helpers/common_responses'

module GdsApi
  module TestHelpers
    module FactCave 
      include GdsApi::TestHelpers::CommonResponses

      FACT_CAVE_ENDPOINT = Plek.current.find('fact-cave')

      def fact_cave_has_a_fact(slug, value, extra_attrs={})
        response = fact_for_slug(slug, value).merge(extra_attrs)

        stub_request(:get, "#{FACT_CAVE_ENDPOINT}/facts/#{slug}")
          .to_return(:body => response.to_json, :status => 200)
        stub_request(:get, "#{FACT_CAVE_ENDPOINT}/facts/#{slug}.json")
          .to_return(:body => response.to_json, :status => 200)
      end

      def fact_cave_does_not_have_a_fact(slug)
        response = {
          "_response_info" => { "status" => "not found" }
        }

        stub_request(:get, "#{FACT_CAVE_ENDPOINT}/facts/#{slug}")
          .to_return(:body => response.to_json, :status => 404)
        stub_request(:get, "#{FACT_CAVE_ENDPOINT}/facts/#{slug}.json")
          .to_return(:body => response.to_json, :status => 404)
      end

      def fact_for_slug(slug, value = "Sample Value")
        singular_response_base.merge({
          "id" => "#{FACT_CAVE_ENDPOINT}/facts/#{slug}",
          "details" => {
            "description" => "",
            "value" => value,
          },
          "name" => titleize_slug(slug),
          "updated_at" => Time.now.utc.xmlschema,
        })
      end
    end
  end
end
