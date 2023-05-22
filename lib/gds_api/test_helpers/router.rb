require "gds_api/test_helpers/json_client_helper"

module GdsApi
  module TestHelpers
    module Router
      ROUTER_API_ENDPOINT = Plek.find("router-api")

      def stub_router_has_route(path, route, bearer_token = ENV["ROUTER_API_BEARER_TOKEN"])
        stub_get_route(path, bearer_token).to_return(
          status: 200,
          body: route.to_json,
          headers: { "Content-Type" => "application/json" },
        )
      end

      def stub_router_doesnt_have_route(path, bearer_token = ENV["ROUTER_API_BEARER_TOKEN"])
        stub_get_route(path, bearer_token).to_return(status: 404)
      end

      def stub_router_has_backend_route(path, backend_id:, route_type: "exact", disabled: false)
        stub_router_has_route(path, handler: "backend", backend_id: backend_id, disabled: disabled, route_type: route_type)
      end

      def stub_router_has_redirect_route(path, redirect_to:, redirect_type: "permanent", route_type: "exact", disabled: false)
        stub_router_has_route(path, handler: "redirect", redirect_to: redirect_to, redirect_type: redirect_type, disabled: disabled, route_type: route_type)
      end

      def stub_router_has_gone_route(path, route_type: "exact", disabled: false)
        stub_router_has_route(path, handler: "gone", route_type: route_type, disabled: disabled)
      end

      def stub_all_router_registration
        stub_request(:put, %r{\A#{ROUTER_API_ENDPOINT}/backends/[a-z0-9-]+\z})
        stub_request(:put, "#{ROUTER_API_ENDPOINT}/routes")
      end

      def stub_router_backend_registration(backend_id, backend_url)
        backend = { "backend" => { "backend_url" => backend_url } }
        stub_http_request(:put, "#{ROUTER_API_ENDPOINT}/backends/#{backend_id}")
            .with(body: backend.to_json)
            .to_return(status: 201)
      end

      def stub_route_registration(path, type, backend_id)
        stub_route_put({
          route: {
            incoming_path: path,
            route_type: type,
            handler: "backend",
            backend_id: backend_id,
          },
        })
      end

      def stub_redirect_registration(path, type, destination, redirect_type, segments_mode = nil)
        stub_route_put({
          route: {
            incoming_path: path,
            route_type: type,
            handler: "redirect",
            redirect_to: destination,
            redirect_type: redirect_type,
            segments_mode: segments_mode,
          },
        })
      end

      def stub_gone_route_registration(path, type)
        stub_route_put({
          route: {
            incoming_path: path,
            route_type: type,
            handler: "gone",
          },
        })
      end

    private

      def stub_get_route(path, bearer_token)
        stub_http_request(:get, "#{ROUTER_API_ENDPOINT}/routes")
          .with(
            query: { "incoming_path" => path },
            headers: { "Authorization" => "Bearer #{bearer_token}" },
          )
      end

      def stub_route_put(route)
        stub_http_request(:put, "#{ROUTER_API_ENDPOINT}/routes")
            .with(body: route.to_json)
            .to_return(status: 201)
      end
    end
  end
end
