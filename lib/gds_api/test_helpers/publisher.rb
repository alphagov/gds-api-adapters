module GdsApi
  module TestHelpers
    module Publisher
      PUBLISHER_ENDPOINT = "http://publisher.test.alphagov.co.uk"

      def publication_exists(details)
        json = JSON.dump(details)
        uri = "#{PUBLISHER_ENDPOINT}/publications/#{details['slug']}.json"
        stub_request(:get, uri).to_return(:body => json, :status => 200)
        return uri
      end
    end
  end
end
