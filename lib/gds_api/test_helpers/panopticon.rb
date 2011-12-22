module GdsApi
  module TestHelpers
    module Panopticon
      PANOPTICON_ENDPOINT = 'http://panopticon.test.alphagov.co.uk'

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
    end
  end
end
