require 'webmock'

module GdsApi
  module TestHelpers
    module ContentApi
      class ArtefactStub
        include WebMock::API
        # This is ugly, but the nicest way we found to get access to artefact_for_slug
        include GdsApi::TestHelpers::ContentApi

        attr_accessor :slug, :query_parameters, :response_body, :response_status

        def initialize(slug)
          @slug = slug
          @query_parameters = {}
          @response_body = artefact_for_slug(slug)
          @response_status = 200
        end
        
        def with_query_parameters(hash)
          @query_parameters = hash
          self
        end

        def with_response_body(response_body)
          @response_body = response_body
          self
        end

        def with_response_status(response_status)
          @response_status = response_status
          self
        end

        # Nothing is stubbed until this is called
        def stub
          stub_request(:get, url_without_query)
              .with(query: hash_including(comparable_query_params))
              .to_return(status: @response_status, body: @response_body.to_json)
        end
        
        private
          def url_without_query
            "#{CONTENT_API_ENDPOINT}/#{slug}.json"
          end

          # Ensure that all keys and values are strings 
          # because Webmock doesn't handle symbols
          def comparable_query_params
            @query_parameters.each_with_object({}) do |(k,v),hash| 
              hash[k.to_s] = v.nil? ? v : v.to_s
            end
          end
      end
    end
  end
end