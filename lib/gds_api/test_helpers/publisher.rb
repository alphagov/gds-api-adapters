require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module Publisher
      # Generally true. If you are initializing the client differently,
      # you could redefine/override the constant or stub directly.
      PUBLISHER_ENDPOINT = Plek.current.find("publisher")

      def publication_exists(details, options = {})
        json = JSON.dump(details)
        uri = "#{PUBLISHER_ENDPOINT}/publications/#{details['slug']}.json"
        if options[:edition]
          uri += "?edition=#{options[:edition]}"
        end
        stub_request(:get, uri).to_return(:body => json, :status => 200)
        return uri
      end

      def publication_exists_for_snac(snac, details)
        json = JSON.dump(details)
        uri = "#{PUBLISHER_ENDPOINT}/publications/#{details['slug']}.json"
        stub_request(:get, uri).to_return(:body => json, :status => 200)
        stub_request(:get, uri).with(:query => {:snac => snac.to_s}).to_return(:body => json, :status => 200)
        return uri
      end

      def publication_does_not_exist(details)
        uri = "#{PUBLISHER_ENDPOINT}/publications/#{details['slug']}.json"
        stub_request(:get, uri).to_return(:body => 'Not Found', :status => 404)
        return uri
      end

      def council_exists_for_slug(input_details, output_details)
        json = JSON.dump(output_details)
        slug = input_details.delete('slug')
        uri = "#{PUBLISHER_ENDPOINT}/local_transactions/#{slug}/verify_snac.json"
        stub_request(:post, uri).with(:body => JSON.dump(input_details),
          :headers => GdsApi::JsonClient::DEFAULT_REQUEST_HEADERS).
          to_return(:body => json, :status => 200)
      end

      def no_council_for_slug(slug)
        uri = "#{PUBLISHER_ENDPOINT}/local_transactions/#{slug}.json"
        stub_request(:post, uri).to_return(:body => "", :status => 404)
      end
    end
  end
end
