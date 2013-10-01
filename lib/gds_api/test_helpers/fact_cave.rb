require 'gds_api/test_helpers/json_client_helper'
require 'gds_api/test_helpers/common_responses'

module GdsApi
  module TestHelpers
    module FactCave 
      include GdsApi::TestHelpers::CommonResponses

      FACT_CAVE_ENDPOINT = Plek.current.find('fact-cave')

      def fact_cave_has_a_fact(slug, value, options={})
        response = fact_for_slug(slug, value, options)

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

      # Creates a sample fact-cave response hash.
      #   slug - the slug for the fact (also used to generate the title)
      #   value - the raw value for the fact
      #   options:
      #     formatted_value - the formatted value to use.  If unspecified, this is generated based on the type
      #     type - the type of the fact - one of [:currency, :date, :numeric, :text].  Defaults to :text
      #     currency - for the :currency type, an optional currency symbol to prepend to the generated formatted_value
      #     unit - for :numeric types, an optional unit to append to the generated formatted_value
      def fact_for_slug(slug, value = "Sample Value", options = {})
        formatted_value = options[:formatted_value]
        formatted_value ||= case options[:type]
        when :date
          value.strftime("%e %B %Y")
        when :numeric
          "#{value.to_s}#{options[:unit]}"
        when :currency
          "#{options[:currency]}#{sprintf("%.2f", value)}"
        when :text, nil
          value
        else
          raise "Unknown fact type #{options[:type]}"
        end

        singular_response_base.merge({
          "id" => "#{FACT_CAVE_ENDPOINT}/facts/#{slug}",
          "details" => {
            "description" => "",
            "value" => value,
            "formatted_value" => formatted_value,
          },
          "name" => titleize_slug(slug),
          "updated_at" => Time.now.utc.xmlschema,
        })
      end
    end
  end
end
