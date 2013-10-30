require 'test_helper'
require 'gds_api/router'

describe GdsApi::Router do

  before do
    @base_api_url = "http://router-api.example.com"
    @api = GdsApi::Router.new(@base_api_url)
  end

  describe "managing backends" do
    describe "fetching details about a backend" do
      it "should return backend details" do
        req = WebMock.stub_request(:get, "#{@base_api_url}/backends/foo").
          to_return(:body => {"backend_id" => "foo", "backend_url" => "http://foo.example.com/"}.to_json,
                    :headers => {"Content-type" => "application/json"})

        response = @api.get_backend("foo")
        assert_equal 200, response.code
        assert_equal "http://foo.example.com/", response.backend_url

        assert_requested(req)
      end

      it "should return nil for a non-existend backend" do
        req = WebMock.stub_request(:get, "#{@base_api_url}/backends/foo").
          to_return(:status => 404)

        response = @api.get_backend("foo")
        assert_nil response

        assert_requested(req)
      end

      it "should URI escape the given ID" do
        req = WebMock.stub_request(:get, "#{@base_api_url}/backends/foo+bar").
          to_return(:status => 404)

        response = @api.get_backend("foo bar")
        assert_nil response

        assert_requested(req)
      end
    end

    describe "creating/updating a backend" do
      it "should allow creating/updating a backend" do
        req = WebMock.stub_request(:put, "#{@base_api_url}/backends/foo").
          with(:body => {"backend" => {"backend_url" => "http://foo.example.com/"}}.to_json).
          to_return(:status => 201, :body => {"backend_id" => "foo", "backend_url" => "http://foo.example.com/"}.to_json,
                    :headers => {"Content-type" => "application/json"})

        response = @api.add_backend("foo", "http://foo.example.com/")
        assert_equal 201, response.code
        assert_equal "http://foo.example.com/", response.backend_url

        assert_requested(req)
      end

      it "should raise an error if creating/updating a backend fails" do
        response_data = {"backend_id" => "foo", "backend_url" => "ftp://foo.example.com/", "errors" => {"backend_url" => "is not an HTTP URL"}}
        req = WebMock.stub_request(:put, "#{@base_api_url}/backends/foo").
          with(:body => {"backend" => {"backend_url" => "http://foo.example.com/"}}.to_json).
          to_return(:status => 400, :body => response_data.to_json, :headers => {"Content-type" => "application/json"})

        e = nil
        begin
          @api.add_backend("foo", "http://foo.example.com/")
        rescue GdsApi::HTTPErrorResponse => ex
          e = ex
        end

        refute_nil e
        assert_equal 400, e.code
        assert_equal response_data, e.error_details

        assert_requested(req)
      end

      it "should URI escape the passed id" do
        req = WebMock.stub_request(:put, "#{@base_api_url}/backends/foo+bar").
          with(:body => {"backend" => {"backend_url" => "http://foo.example.com/"}}.to_json).
          to_return(:status => 404, :body => "Not found")

        # We expect a GdsApi::HTTPErrorResponse, but we want to ensure nothing else is raised
        begin
          @api.add_backend("foo bar", "http://foo.example.com/")
        rescue GdsApi::HTTPErrorResponse
        end

        assert_requested(req)
      end
    end

    describe "deleting a backend" do
      it "allow deleting a backend" do
        req = WebMock.stub_request(:delete, "#{@base_api_url}/backends/foo").
          to_return(:status => 200, :body => {"backend_id" => "foo", "backend_url" => "http://foo.example.com/"}.to_json,
                    :headers => {"Content-type" => "application/json"})

        response = @api.delete_backend("foo")
        assert_equal 200, response.code
        assert_equal "http://foo.example.com/", response.backend_url

        assert_requested(req)
      end

      it "should raise an error if deleting the backend fails" do
        response_data = {"backend_id" => "foo", "backend_url" => "ftp://foo.example.com/", "errors" => {"base" => "Backend has routes - can't delete"}}
        req = WebMock.stub_request(:delete, "#{@base_api_url}/backends/foo").
          to_return(:status => 400, :body => response_data.to_json, :headers => {"Content-type" => "application/json"})

        e = nil
        begin
          @api.delete_backend("foo")
        rescue GdsApi::HTTPErrorResponse => ex
          e = ex
        end

        refute_nil e
        assert_equal 400, e.code
        assert_equal response_data, e.error_details

        assert_requested(req)
      end

      it "should URI escape the passed id" do
        req = WebMock.stub_request(:delete, "#{@base_api_url}/backends/foo+bar").
          to_return(:status => 404, :body => "Not found")

        # We expect a GdsApi::HTTPErrorResponse, but we want to ensure nothing else is raised
        begin
          @api.delete_backend("foo bar")
        rescue GdsApi::HTTPErrorResponse
        end

        assert_requested(req)
      end
    end
  end

  describe "managing routes" do
    describe "fetching a route" do
      it "should return the route details" do
        route_data = {"incoming_path" => "/foo", "route_type" => "exact", "handler" => "backend", "backend_id" => "foo"}
        req = WebMock.stub_request(:get, "#{@base_api_url}/routes").
          with(:query => {"incoming_path" => "/foo", "route_type" => "exact"}).
          to_return(:status => 200, :body => route_data.to_json, :headers => {"Content-type" => "application/json"})

        response = @api.get_route("/foo", "exact")
        assert_equal 200, response.code
        assert_equal "foo", response.backend_id

        assert_requested(req)
      end

      it "should return nil if nothing found" do
        req = WebMock.stub_request(:get, "#{@base_api_url}/routes").
          with(:query => {"incoming_path" => "/foo", "route_type" => "exact"}).
          to_return(:status => 404)

        response = @api.get_route("/foo", "exact")
        assert_nil response

        assert_requested(req)
      end

      it "should escape the params" do
        # The WebMock query matcher matches unescaped params.  The call blows up if they're not escaped

        req = WebMock.stub_request(:get, "#{@base_api_url}/routes").
          with(:query => {"incoming_path" => "/foo bar", "route_type" => "exa ct"}).
          to_return(:status => 404)

        response = @api.get_route("/foo bar", "exa ct")
        assert_nil response

        assert_requested(req)
      end
    end

    describe "creating/updating a route" do
      it "should allow creating/updating a route" do
        route_data = {"incoming_path" => "/foo", "route_type" => "exact", "handler" => "backend", "backend_id" => "foo"}
        req = WebMock.stub_request(:put, "#{@base_api_url}/routes").
          with(:body => {"route" => route_data}.to_json).
          to_return(:status => 201, :body => route_data.to_json, :headers => {"Content-type" => "application/json"})

        response = @api.add_route("/foo", "exact", "foo")
        assert_equal 201, response.code
        assert_equal "foo", response.backend_id

        assert_requested(req)
      end

      it "should raise an error if creating/updating the route fails" do
        route_data = {"incoming_path" => "/foo", "route_type" => "exact", "handler" => "backend", "backend_id" => "foo"}
        response_data = route_data.merge("errors" => {"backend_id" => "does not exist"})

        req = WebMock.stub_request(:put, "#{@base_api_url}/routes").
          with(:body => {"route" => route_data}.to_json).
          to_return(:status => 400, :body => response_data.to_json, :headers => {"Content-type" => "application/json"})

        e = nil
        begin
          @api.add_route("/foo", "exact", "foo")
        rescue GdsApi::HTTPErrorResponse => ex
          e = ex
        end

        refute_nil e
        assert_equal 400, e.code
        assert_equal response_data, e.error_details

        assert_requested(req)
      end
    end

    describe "deleting a route" do
      it "should allow deleting a route" do
        route_data = {"incoming_path" => "/foo", "route_type" => "exact", "handler" => "backend", "backend_id" => "foo"}
        req = WebMock.stub_request(:delete, "#{@base_api_url}/routes").
          with(:query => {"incoming_path" => "/foo", "route_type" => "exact"}).
          to_return(:status => 200, :body => route_data.to_json, :headers => {"Content-type" => "application/json"})

        response = @api.delete_route("/foo", "exact")
        assert_equal 200, response.code
        assert_equal "foo", response.backend_id

        assert_requested(req)
      end

      it "should raise HTTPNotFound if nothing found" do
        req = WebMock.stub_request(:delete, "#{@base_api_url}/routes").
          with(:query => {"incoming_path" => "/foo", "route_type" => "exact"}).
          to_return(:status => 404)

        e = nil
        begin
          @api.delete_route("/foo", "exact")
        rescue GdsApi::HTTPNotFound => ex
          e = ex
        end

        refute_nil e
        assert_equal 404, e.code

        assert_requested(req)
      end

      it "should escape the params" do
        # The WebMock query matcher matches unescaped params.  The call blows up if they're not escaped

        req = WebMock.stub_request(:delete, "#{@base_api_url}/routes").
          with(:query => {"incoming_path" => "/foo bar", "route_type" => "exa ct"}).
          to_return(:status => 404)

        begin
          @api.delete_route("/foo bar", "exa ct")
        rescue GdsApi::HTTPNotFound
        end

        assert_requested(req)
      end
    end
  end
end
