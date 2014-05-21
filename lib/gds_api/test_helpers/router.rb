require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module Router
      ROUTER_API_ENDPOINT = Plek.current.find('router-api')

      def stub_route_registration(path, type, backend_id)
        route = { route: {
                    incoming_path: path,
                    route_type: type,
                    handler: 'backend',
                    backend_id: backend_id }
                }

        stub_router_put(route)
        stub_http_request(:post, "#{ROUTER_API_ENDPOINT}/routes/commit")
      end

      def stub_redirect_registration(path, type, destination, redirect_type)
        redirect = { route: {
                      incoming_path: path,
                      route_type: type,
                      handler: 'redirect',
                      redirect_to: destination,
                      redirect_type: redirect_type }
                  }

        stub_router_put(redirect)
        stub_http_request(:post, "#{ROUTER_API_ENDPOINT}/routes/commit")
      end

    private

      def stub_router_put(route)
        stub_http_request(:put, "#{ROUTER_API_ENDPOINT}/routes")
            .with(:body => route.to_json)
            .to_return(:status => 201)
      end
    end
  end
end
