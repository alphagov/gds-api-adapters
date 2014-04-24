require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module Panopticon
      # Generally true. If you are initializing the client differently,
      # you could redefine/override the constant or stub directly.
      PANOPTICON_ENDPOINT = Plek.current.find('panopticon')

      def stringify_hash_keys(input_hash)
        input_hash.inject({}) do |options, (key, value)|
          options[key.to_s] = value
          options
        end
      end

      def panopticon_has_metadata(metadata)
        metadata = stringify_hash_keys(metadata)

        json = JSON.dump(metadata)

        urls = []
        urls << "#{PANOPTICON_ENDPOINT}/artefacts/#{metadata['id']}.json" if metadata['id']
        urls << "#{PANOPTICON_ENDPOINT}/artefacts/#{metadata['slug']}.json" if metadata['slug']

        urls.each { |url| stub_request(:get, url).to_return(:status => 200, :body => json, :headers => {}) }

        return urls.first
      end

      def panopticon_has_no_metadata_for(slug)
        url = "#{PANOPTICON_ENDPOINT}/artefacts/#{slug}.json"
        stub_request(:get, url).to_return(:status => 404, :body => "", :headers => {})
      end

      def stub_panopticon_default_artefact
        stub_request(:get, %r{\A#{PANOPTICON_ENDPOINT}/artefacts}).to_return { |request|
          # return a response with only a slug, and set that slug to match the requested artefact slug
          {:body => JSON.dump("slug" => request.uri.path.split('/').last.chomp('.json'))}
        }
      end

      def stub_artefact_registration(slug, request_details = nil)
        stub = stub_http_request(:put, "#{PANOPTICON_ENDPOINT}/artefacts/#{slug}.json")
        stub.with(:body => request_details.to_json) unless request_details.nil?
        stub.to_return(:status => 201)
      end
    end
  end
end
