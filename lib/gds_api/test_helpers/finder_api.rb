require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module FinderApi
      FINDER_API_ENDPOINT = Plek.current.find('finder-api')

      def finder_api_has_schema(finder_slug)
        stub_request(:get, "#{FINDER_API_ENDPOINT}/finders/#{finder_slug}/schema.json")
          .with(:headers => {'Content-Type'=>'application/json'})
          .to_return(:status => 200, :body => schema_fixture(finder_slug))
      end

    private
      def schema_fixture(finder_slug)
        case finder_slug
        when "aaib-reports"
          schema_content("aaib-report-schema.json")
        when "international-development-funds"
          schema_content('international-development-funding-schema.json')
        when "cma-cases"
          schema_content('cma-case-schema.json')
        else raise "Unknown schema type: #{schema_type}"
        end
      end

      def schema_content(filename)
        File.read(
          File.expand_path(
            "../../../../test/fixtures/finder_api/#{filename}",
            __FILE__
          )
        )
      end
    end
  end
end
