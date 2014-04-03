require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module FinderApi
      FINDER_API_ENDPOINT = Plek.current.find('finder-api')

      def finder_api_has_schema(finder_slug, schema_fixture = FinderApi.schema_fixture)
        stub_request(:get, "#{FINDER_API_ENDPOINT}/finders/#{finder_slug}/schema.json")
          .with(:headers => {'Content-Type'=>'application/json'})
          .to_return(:status => 200, :body => schema_fixture)
      end

      def self.schema_fixture
        File.read(
          File.expand_path(
            "../../../../test/fixtures/finder_api/cma-case-schema.json",
            __FILE__
          )
        )
      end
    end
  end
end
