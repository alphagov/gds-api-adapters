require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module Panopticon
      PANOPTICON_ENDPOINT = 'https://panopticon.test.alphagov.co.uk'

      def panopticon_has_metadata(metadata)
        json = JSON.dump(metadata)

        urls = []
        id   = metadata[:id]
        slug = metadata[:slug]
        urls << "#{PANOPTICON_ENDPOINT}/artefacts/#{id}.json"   if id
        urls << "#{PANOPTICON_ENDPOINT}/artefacts/#{slug}.json" if slug

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

    end
  end
end
