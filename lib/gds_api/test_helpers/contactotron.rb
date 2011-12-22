module GdsApi
  module TestHelpers
    module Contactotron

      def contactotron_has_contact(uri, details)
        json = JSON.dump(details)
        stub_request(:get, uri).to_return(:status => 200, :body => json, :headers => {})
        return uri
      end
    end
  end
end
