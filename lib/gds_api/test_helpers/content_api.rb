require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module ContentApi
      CONTENT_API_ENDPOINT = 'https://contentapi.test.alphagov.co.uk'

      def content_api_has_root_sections(slugs)
        body = plural_response_base.merge(
          "results" => slugs.map do |slug|
            {
              "id" => "http://contentapi.test.gov.uk/tags/#{slug}.json",
              "web_url" => "http://www.test.gov.uk/browse/#{slug}",
              "title" => slug.gsub("-", " ").capitalize,
              "details" => {
                "type" => "section",
                "description" => "#{slug} description"
              },
              "parent" => nil
            }
          end
        )
        url = "#{CONTENT_API_ENDPOINT}/tags.json?type=section"
        stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: {})
      end

      private 
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
