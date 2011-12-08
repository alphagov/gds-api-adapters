module GdsApi
  module TestHelpers
    module Panopticon
      def panopticon_has_metadata(metadata)
        json = JSON.dump(metadata)
        url = "http://panopticon.test.alphagov.co.uk/artefacts/#{metadata['id']}.json"
        stub_request(:get, url).
          to_return(:status => 200, :body => json, :headers => {})
        return url
      end
    end
  end
end
