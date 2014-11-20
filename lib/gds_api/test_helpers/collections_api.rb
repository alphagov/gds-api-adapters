require 'gds_api/test_helpers/json_client_helper'
require 'json'

module GdsApi
  module TestHelpers
    module CollectionsApi
      COLLECTIONS_API_ENDPOINT = Plek.current.find('collections-api')

      def collections_api_has_content_for(base_path, options={})
        body_options = options.delete(:return_body_options) || {}

        params = options.any? ? "?#{Rack::Utils.build_nested_query(options)}" : ''
        url = COLLECTIONS_API_ENDPOINT + "/specialist-sectors" + base_path + params

        stub_request(:get, url).to_return(
          status: 200,
          body: body_with_options(
            body_options.merge(base_path: base_path)
          ).to_json,
        )
      end

      def collections_api_has_no_content_for(base_path)
        url = COLLECTIONS_API_ENDPOINT + "/specialist-sectors" + base_path

        stub_request(:get, url).to_return(
          status: 404
        )
      end

      def collections_api_example_documents
        [
          {
            title: "Oil rig safety requirements",
            link: "http://example.com/documents/oil-rig-safety-requirements",
            public_updated_at: "2014-10-27T09:35:57+00:00",
            latest_change_note: "Updated topics"
          },
          {
            title: "Undersea piping restrictions",
            link: "http://example.com/documents/undersea-piping-restrictions",
            public_updated_at: "2014-10-15T09:36:18+01:00",
            latest_change_note: nil
          },
          {
            title: "North sea shipping lanes",
            link: "http://example.com/documents/north-sea-shipping-lanes",
            public_updated_at: "2014-10-04T09:36:42+01:00",
            latest_change_note: "Corrected shipping lane"
          },
          {
            title: "Oil rig staffing",
            link: "http://example.com/documents/oil-rig-staffing",
            public_updated_at: "2014-09-22T09:37:00+01:00",
            latest_change_note: "Added annual leave allowances"
          },
        ]
      end

    private

      def body_with_options(options)
        {
          base_path: options.fetch(:base_path),
          title: 'Example title',
          description: 'example description',
          public_updated_at: "2014-03-04T13:58:11+00:00",
          parent: {
            id: "http://example.com/oil-and-gas",
            web_url: "http://example.com/browse/oil-and-gas",
            details: {
              description: nil,
              short_description: nil,
              type: "section",
            },
            content_with_tag: {
              id: "http://example.com/with_tag.json?section=oil-and-gas",
              web_url: "http://example.com/browse/oil-and-gas"
            },
            parent: nil,
            title: "Oil and gas",
            state: "live",
          },
          details: {
            groups: [
              # Curated content excluding untagged content
              {
                name: "Oil rigs",
                contents: [
                  {
                    web_url: "http://example.com/api/oil-rig-safety-requirements.json",
                    title: "Oil rig safety requirements",
                  },
                  {
                    web_url: "http://example.com/api/oil-rig-staffing.json",
                    title: "Oil rig staffing",
                  }
                ]
              },
              {
                name: "Piping",
                contents: [
                  {
                    web_url: "http://example.com/api/undersea-piping-restrictions.json",
                    title: "Undersea piping restrictions",
                  }
                ]
              },
              # Uncurated content
              {
                name: "Other",
                contents: [
                  {
                    web_url: "http://example.com/api/north-sea-shipping-lanes.json",
                    title: "North sea shipping lanes",
                  }
                ]
              }
            ],
            documents: collections_api_example_documents,
            documents_start: options.fetch(:start, 0),
            documents_total: options.fetch(:total, collections_api_example_documents.size),
          }
        }
      end
    end
  end
end
