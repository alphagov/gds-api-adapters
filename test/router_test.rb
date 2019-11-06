require "test_helper"
require "gds_api/router"
require "gds_api/test_helpers/router"

describe GdsApi::Router do
  include GdsApi::TestHelpers::Router

  before do
    @base_api_url = Plek.find("router-api")
    @api = GdsApi::Router.new(@base_api_url, bearer_token: "token")
  end

  around do |test|
    ClimateControl.modify ROUTER_API_BEARER_TOKEN: "token" do
      test.call
    end
  end

  describe "managing backends" do
    describe "fetching details about a backend" do
      it "should return backend details" do
        req = WebMock.stub_request(:get, "#{@base_api_url}/backends/foo").
          to_return(body: { "backend_id" => "foo", "backend_url" => "http://foo.example.com/" }.to_json,
                    headers: { "Content-type" => "application/json" })

        response = @api.get_backend("foo")
        assert_equal 200, response.code
        assert_equal "http://foo.example.com/", response["backend_url"]

        assert_requested(req)
      end

      it "raises for a non-existend backend" do
        req = WebMock.stub_request(:get, "#{@base_api_url}/backends/foo").
          to_return(status: 404)

        assert_raises(GdsApi::HTTPNotFound) do
          @api.get_backend("foo")
        end

        assert_requested(req)
      end

      it "should URI escape the given ID" do
        req = WebMock.stub_request(:get, "#{@base_api_url}/backends/foo+bar").
          to_return(status: 404)

        assert_raises(GdsApi::HTTPNotFound) do
          @api.get_backend("foo bar")
        end

        assert_requested(req)
      end
    end

    describe "creating/updating a backend" do
      it "should allow creating/updating a backend" do
        req = WebMock.stub_request(:put, "#{@base_api_url}/backends/foo").
          with(body: { "backend" => { "backend_url" => "http://foo.example.com/" } }.to_json).
          to_return(status: 201, body: { "backend_id" => "foo", "backend_url" => "http://foo.example.com/" }.to_json,
                    headers: { "Content-type" => "application/json" })

        response = @api.add_backend("foo", "http://foo.example.com/")
        assert_equal 201, response.code
        assert_equal "http://foo.example.com/", response["backend_url"]

        assert_requested(req)
      end

      it "should raise an error if creating/updating a backend fails" do
        response_data = {
          "backend_id" => "foo",
          "backend_url" => "ftp://foo.example.com/",
          "errors" => { "backend_url" => "is not an HTTP URL" },
        }

        req = WebMock.stub_request(:put, "#{@base_api_url}/backends/foo")
          .with(body: { "backend" => { "backend_url" => "http://foo.example.com/" } }.to_json)
          .to_return(status: 400, body: response_data.to_json, headers: { "Content-type" => "application/json" })

        e = assert_raises(GdsApi::HTTPErrorResponse) do
          @api.add_backend("foo", "http://foo.example.com/")
        end

        assert_equal 400, e.code
        assert_equal response_data, e.error_details

        assert_requested(req)
      end

      it "should URI escape the passed id" do
        req = WebMock.stub_request(:put, "#{@base_api_url}/backends/foo+bar").
          with(body: { "backend" => { "backend_url" => "http://foo.example.com/" } }.to_json).
          to_return(status: 404, body: "Not found")

        # We expect a GdsApi::HTTPErrorResponse, but we want to ensure nothing else is raised
        begin
          @api.add_backend("foo bar", "http://foo.example.com/")
        rescue GdsApi::HTTPErrorResponse
          nil
        end

        assert_requested(req)
      end
    end

    describe "deleting a backend" do
      it "allow deleting a backend" do
        req = WebMock.stub_request(:delete, "#{@base_api_url}/backends/foo").
          to_return(status: 200, body: { "backend_id" => "foo", "backend_url" => "http://foo.example.com/" }.to_json,
                    headers: { "Content-type" => "application/json" })

        response = @api.delete_backend("foo")
        assert_equal 200, response.code
        assert_equal "http://foo.example.com/", response["backend_url"]

        assert_requested(req)
      end

      it "should raise an error if deleting the backend fails" do
        response_data = {
          "backend_id" => "foo",
          "backend_url" => "ftp://foo.example.com/",
          "errors" => { "base" => "Backend has routes - can't delete" },
        }

        req = WebMock.stub_request(:delete, "#{@base_api_url}/backends/foo")
          .to_return(status: 400, body: response_data.to_json, headers: { "Content-type" => "application/json" })

        e = assert_raises(GdsApi::HTTPErrorResponse) do
          @api.delete_backend("foo")
        end

        assert_equal 400, e.code
        assert_equal response_data, e.error_details

        assert_requested(req)
      end

      it "should URI escape the passed id" do
        req = WebMock.stub_request(:delete, "#{@base_api_url}/backends/foo+bar").
          to_return(status: 404, body: "Not found")

        assert_raises GdsApi::HTTPErrorResponse do
          @api.delete_backend("foo bar")
        end

        assert_requested(req)
      end
    end
  end

  describe "managing routes" do
    before :each do
      @commit_req = WebMock.stub_request(:post, "#{@base_api_url}/routes/commit").
        to_return(status: 200, body: "Routers updated")
    end

    describe "fetching a route" do
      it "should return the backend route details" do
        req = stub_router_has_backend_route("/foo", backend_id: "foo")

        response = @api.get_route("/foo")
        assert_equal 200, response.code
        assert_equal "foo", response["backend_id"]

        assert_requested(req)
        assert_not_requested(@commit_req)
      end

      it "should raise if nothing found" do
        req = stub_router_doesnt_have_route("/foo")

        assert_raises(GdsApi::HTTPNotFound) do
          @api.get_route("/foo")
        end

        assert_requested(req)
        assert_not_requested(@commit_req)
      end

      it "should return the gone route details" do
        stub_router_has_gone_route("/foo")

        response = @api.get_route("/foo")
        assert_equal 200, response.code
        assert_equal "gone", response["handler"]
      end

      it "should return the redirect route details" do
        stub_router_has_redirect_route("/foo", redirect_to: "/bar")

        response = @api.get_route("/foo")
        assert_equal 200, response.code
        assert_equal "redirect", response["handler"]
        assert_equal "/bar", response["redirect_to"]
      end

      it "should escape the params" do
        # The WebMock query matcher matches unescaped params.  The call blows up if they're not escaped

        req = WebMock.stub_request(:get, "#{@base_api_url}/routes").
          with(query: { "incoming_path" => "/foo bar" }).
          to_return(status: 404)

        assert_raises(GdsApi::HTTPNotFound) do
          @api.get_route("/foo bar")
        end

        assert_requested(req)
        assert_not_requested(@commit_req)
      end
    end

    describe "creating/updating a route" do
      it "should allow creating/updating a route" do
        route_data = { "incoming_path" => "/foo", "route_type" => "exact", "handler" => "backend", "backend_id" => "foo" }
        req = WebMock.stub_request(:put, "#{@base_api_url}/routes").
          with(body: { "route" => route_data }.to_json).
          to_return(status: 201, body: route_data.to_json, headers: { "Content-type" => "application/json" })

        response = @api.add_route("/foo", "exact", "foo")
        assert_equal 201, response.code
        assert_equal "foo", response["backend_id"]

        assert_requested(req)
        assert_not_requested(@commit_req)
      end

      it "should commit the routes when asked to" do
        req = WebMock.stub_request(:put, "#{@base_api_url}/routes").
          to_return(status: 201, body: {}.to_json, headers: { "Content-type" => "application/json" })

        @api.add_route("/foo", "exact", "foo", commit: true)

        assert_requested(req)
        assert_requested(@commit_req)
      end

      it "should raise an error if creating/updating the route fails" do
        route_data = { "incoming_path" => "/foo", "route_type" => "exact", "handler" => "backend", "backend_id" => "foo" }
        response_data = route_data.merge("errors" => { "backend_id" => "does not exist" })

        req = WebMock.stub_request(:put, "#{@base_api_url}/routes")
          .with(body: { "route" => route_data }.to_json)
          .to_return(status: 400, body: response_data.to_json, headers: { "Content-type" => "application/json" })

        e = assert_raises(GdsApi::HTTPErrorResponse) do
          @api.add_route("/foo", "exact", "foo")
        end

        assert_equal 400, e.code
        assert_equal response_data, e.error_details

        assert_requested(req)
        assert_not_requested(@commit_req)
      end
    end

    describe "creating/updating a redirect route" do
      it "should allow creating/updating a redirect route" do
        route_data = { "incoming_path" => "/foo", "route_type" => "exact", "handler" => "redirect",
          "redirect_to" => "/bar", "redirect_type" => "permanent", "segments_mode" => nil }
        req = WebMock.stub_request(:put, "#{@base_api_url}/routes").
          with(body: { "route" => route_data }.to_json).
          to_return(status: 201, body: route_data.to_json, headers: { "Content-type" => "application/json" })

        response = @api.add_redirect_route("/foo", "exact", "/bar")
        assert_equal 201, response.code
        assert_equal "/bar", response["redirect_to"]

        assert_requested(req)
        assert_not_requested(@commit_req)
      end

      it "should allow creating/updating a temporary redirect route" do
        route_data = { "incoming_path" => "/foo", "route_type" => "exact", "handler" => "redirect",
          "redirect_to" => "/bar", "redirect_type" => "temporary", "segments_mode" => nil }
        req = WebMock.stub_request(:put, "#{@base_api_url}/routes").
          with(body: { "route" => route_data }.to_json).
          to_return(status: 201, body: route_data.to_json, headers: { "Content-type" => "application/json" })

        response = @api.add_redirect_route("/foo", "exact", "/bar", "temporary")
        assert_equal 201, response.code
        assert_equal "/bar", response["redirect_to"]

        assert_requested(req)
        assert_not_requested(@commit_req)
      end

      it "should allow creating/updating a redirect route which preserves segments" do
        route_data = { "incoming_path" => "/foo", "route_type" => "exact", "handler" => "redirect",
          "redirect_to" => "/bar", "redirect_type" => "temporary", "segments_mode" => "preserve" }
        req = WebMock.stub_request(:put, "#{@base_api_url}/routes").
          with(body: { "route" => route_data }.to_json).
          to_return(status: 201, body: route_data.to_json, headers: { "Content-type" => "application/json" })

        response = @api.add_redirect_route("/foo", "exact", "/bar", "temporary", segments_mode: "preserve")
        assert_equal 201, response.code
        assert_equal "/bar", response["redirect_to"]

        assert_requested(req)
        assert_not_requested(@commit_req)
      end

      it "should commit the routes when asked to" do
        req = WebMock.stub_request(:put, "#{@base_api_url}/routes").
          to_return(status: 201, body: {}.to_json, headers: { "Content-type" => "application/json" })

        @api.add_redirect_route("/foo", "exact", "/bar", "temporary", commit: true)

        assert_requested(req)
        assert_requested(@commit_req)
      end

      it "should raise an error if creating/updating the redirect route fails" do
        route_data = { "incoming_path" => "/foo", "route_type" => "exact", "handler" => "redirect",
          "redirect_to" => "bar", "redirect_type" => "permanent", "segments_mode" => nil }
        response_data = route_data.merge("errors" => { "redirect_to" => "is not a valid URL path" })

        req = WebMock.stub_request(:put, "#{@base_api_url}/routes")
          .with(body: { "route" => route_data }.to_json)
          .to_return(status: 400, body: response_data.to_json, headers: { "Content-type" => "application/json" })

        e = assert_raises(GdsApi::HTTPErrorResponse) do
          @api.add_redirect_route("/foo", "exact", "bar")
        end

        assert_equal 400, e.code
        assert_equal response_data, e.error_details

        assert_requested(req)
        assert_not_requested(@commit_req)
      end
    end

    describe "#add_gone_route" do
      it "should allow creating/updating a gone route" do
        route_data = { "incoming_path" => "/foo", "route_type" => "exact", "handler" => "gone" }
        req = WebMock.stub_request(:put, "#{@base_api_url}/routes").
          with(body: { "route" => route_data }.to_json).
          to_return(status: 201, body: route_data.to_json, headers: { "Content-type" => "application/json" })

        response = @api.add_gone_route("/foo", "exact")
        assert_equal 201, response.code
        assert_equal "/foo", response["incoming_path"]

        assert_requested(req)
        assert_not_requested(@commit_req)
      end

      it "should commit the routes when asked to" do
        req = WebMock.stub_request(:put, "#{@base_api_url}/routes").
          to_return(status: 201, body: {}.to_json, headers: { "Content-type" => "application/json" })

        @api.add_gone_route("/foo", "exact", commit: true)

        assert_requested(req)
        assert_requested(@commit_req)
      end

      it "should raise an error if creating/updating the gone route fails" do
        route_data = { "incoming_path" => "foo", "route_type" => "exact", "handler" => "gone" }
        response_data = route_data.merge("errors" => { "incoming_path" => "is not a valid URL path" })

        req = WebMock.stub_request(:put, "#{@base_api_url}/routes")
          .with(body: { "route" => route_data }.to_json)
          .to_return(status: 400, body: response_data.to_json, headers: { "Content-type" => "application/json" })

        e = assert_raises(GdsApi::HTTPErrorResponse) do
          @api.add_gone_route("foo", "exact")
        end

        assert_equal 400, e.code
        assert_equal response_data, e.error_details

        assert_requested(req)
        assert_not_requested(@commit_req)
      end
    end

    describe "deleting a route" do
      it "should allow deleting a route" do
        route_data = { "incoming_path" => "/foo", "route_type" => "exact", "handler" => "backend", "backend_id" => "foo" }
        req = WebMock.stub_request(:delete, "#{@base_api_url}/routes").
          with(query: { "incoming_path" => "/foo" }).
          to_return(status: 200, body: route_data.to_json, headers: { "Content-type" => "application/json" })

        response = @api.delete_route("/foo")
        assert_equal 200, response.code
        assert_equal "foo", response["backend_id"]

        assert_requested(req)
        assert_not_requested(@commit_req)
      end

      it "should commit the routes when asked to" do
        req = WebMock.stub_request(:delete, "#{@base_api_url}/routes").
          with(query: { "incoming_path" => "/foo" }).
          to_return(status: 200, body: {}.to_json, headers: { "Content-type" => "application/json" })

        @api.delete_route("/foo", commit: true)

        assert_requested(req)
        assert_requested(@commit_req)
      end

      it "should raise HTTPNotFound if nothing found" do
        req = WebMock.stub_request(:delete, "#{@base_api_url}/routes").
          with(query: { "incoming_path" => "/foo" }).
          to_return(status: 404)

        e = assert_raises(GdsApi::HTTPNotFound) do
          @api.delete_route("/foo")
        end

        assert_equal 404, e.code

        assert_requested(req)
        assert_not_requested(@commit_req)
      end

      it "should escape the params" do
        # The WebMock query matcher matches unescaped params.  The call blows up if they're not escaped

        req = WebMock.stub_request(:delete, "#{@base_api_url}/routes").
          with(query: { "incoming_path" => "/foo bar" }).
          to_return(status: 404)

        assert_raises GdsApi::HTTPNotFound do
          @api.delete_route("/foo bar")
        end

        assert_requested(req)
      end
    end

    describe "committing the routes" do
      it "should allow committing the routes" do
        @api.commit_routes

        assert_requested(@commit_req)
      end

      it "should raise an error if committing the routes fails" do
        WebMock.stub_request(:post, "#{@base_api_url}/routes/commit").
          to_return(status: 500, body: "Failed to update all routers")

        e = assert_raises(GdsApi::HTTPErrorResponse) do
          @api.commit_routes
        end

        assert_equal 500, e.code
        assert_equal "URL: #{@base_api_url}/routes/commit\nResponse body:\nFailed to update all routers\n\nRequest body:\n{}", e.message
      end
    end
  end
end
