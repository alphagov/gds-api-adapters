require 'gds_api/test_helpers/json_client_helper'

module GdsApi
  module TestHelpers
    module Router
      ROUTER_API_ENDPOINT = Plek.current.find('router-api')

      def stub_all_router_registration
        stub_request(:put, %r{\A#{ROUTER_API_ENDPOINT}/backends/[a-z0-9-]+\z})
        stub_request(:put, "#{ROUTER_API_ENDPOINT}/routes")
        stub_request(:post, "#{ROUTER_API_ENDPOINT}/routes/commit")
      end

      def stub_router_backend_registration(backend_id, backend_url)
        backend = { "backend" => { "backend_url" => backend_url }}
        stub_http_request(:put, "#{ROUTER_API_ENDPOINT}/backends/#{backend_id}")
            .with(:body => backend.to_json)
            .to_return(:status => 201)
      end

      def stub_route_registration(path, type, backend_id)
        route = { route: {
                    incoming_path: path,
                    route_type: type,
                    handler: 'backend',
                    backend_id: backend_id }
                }

        register_stub = stub_route_put(route)
        commit_stub = stub_router_commit
        [register_stub, commit_stub]
      end

      def stub_redirect_registration(path, type, destination, redirect_type)
        redirect = { route: {
                      incoming_path: path,
                      route_type: type,
                      handler: 'redirect',
                      redirect_to: destination,
                      redirect_type: redirect_type }
                  }

        register_stub = stub_route_put(redirect)
        commit_stub = stub_router_commit
        [register_stub, commit_stub]
      end

      def stub_gone_route_registration(path, type)
        route = { route: {
                      incoming_path: path,
                      route_type: type,
                      handler: 'gone' }
                  }

        register_stub = stub_route_put(route)
        commit_stub = stub_router_commit
        [register_stub, commit_stub]
      end

      def stub_router_commit
        stub_http_request(:post, "#{ROUTER_API_ENDPOINT}/routes/commit")
      end

    private

      def stub_route_put(route)
        stub_http_request(:put, "#{ROUTER_API_ENDPOINT}/routes")
            .with(:body => route.to_json)
            .to_return(:status => 201)
      end
    end
  end
end
