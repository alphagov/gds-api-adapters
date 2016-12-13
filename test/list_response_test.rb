require_relative 'test_helper'
require 'gds_api/list_response'

describe GdsApi::ListResponse do
  describe "accessing results" do
    before :each do
    end

    it "should allow Enumerable access to the results array" do
      data = {
        "results" => %w(foo bar baz),
        "total" => 3,
        "_response_info" => {
          "status" => "ok",
        }
      }
      response = GdsApi::ListResponse.new(stub(body: data.to_json), nil)

      assert_equal "foo", response.first
      assert_equal %w(foo bar baz), response.to_a
      assert response.any?
    end

    it "should handle an empty result set" do
      data = {
        "results" => [],
        "total" => 0,
        "_response_info" => {
          "status" => "ok",
        }
      }
      response = GdsApi::ListResponse.new(stub(body: data.to_json), nil)

      assert_equal [], response.to_a
      assert ! response.any?
    end
  end

  describe "handling pagination" do
    before :each do
      page_1 = {
        "results" => %w(foo1 bar1),
        "total" => 6,
        "current_page" => 1, "pages" => 3, "page_size" => 2,
        "_response_info" => {
          "status" => "ok",
          "links" => [
            { "href" => "http://www.example.com/2", "rel" => "next" },
            { "href" => "http://www.example.com/1", "rel" => "self" },
          ]
        }
      }
      page_2 = {
        "results" => %w(foo2 bar2),
        "total" => 6,
        "current_page" => 2, "pages" => 3, "page_size" => 2,
        "_response_info" => {
          "status" => "ok",
          "links" => [
            { "href" => "http://www.example.com/1", "rel" => "previous" },
            { "href" => "http://www.example.com/3", "rel" => "next" },
            { "href" => "http://www.example.com/2", "rel" => "self" },
          ]
        }
      }
      page_3 = {
        "results" => %w(foo3 bar3),
        "total" => 6,
        "current_page" => 3, "pages" => 3, "page_size" => 2,
        "_response_info" => {
          "status" => "ok",
          "links" => [
            { "href" => "http://www.example.com/2", "rel" => "previous" },
            { "href" => "http://www.example.com/3", "rel" => "self" },
          ]
        }
      }
      @p1_response = stub(
        body: page_1.to_json,
        status: 200,
        headers: {
          link: '<http://www.example.com/1>; rel="self", <http://www.example.com/2>; rel="next"'
        }
      )
      @p2_response = stub(
        body: page_2.to_json,
        status: 200,
        headers: {
          link: '<http://www.example.com/2>; rel="self", <http://www.example.com/3>; rel="next", <http://www.example.com/1>; rel="previous"'
        }
      )
      @p3_response = stub(
        body: page_3.to_json,
        status: 200,
        headers: {
          link: '<http://www.example.com/3>; rel="self", <http://www.example.com/1>; rel="previous"'
        }
      )

      @client = stub
      @client.stubs(:get_list).with("http://www.example.com/1").returns(GdsApi::ListResponse.new(@p1_response, @client))
      @client.stubs(:get_list).with("http://www.example.com/2").returns(GdsApi::ListResponse.new(@p2_response, @client))
      @client.stubs(:get_list).with("http://www.example.com/3").returns(GdsApi::ListResponse.new(@p3_response, @client))
    end

    describe "accessing next page" do
      it "should allow accessing the next page" do
        resp = GdsApi::ListResponse.new(@p1_response, @client)
        assert resp.has_next_page?
        assert_equal %w(foo2 bar2), resp.next_page['results']
      end

      it "should return nil with no next page" do
        resp = GdsApi::ListResponse.new(@p3_response, @client)
        assert ! resp.has_next_page?
        assert_equal nil, resp.next_page
      end

      it "should memoize the next_page" do
        resp = GdsApi::ListResponse.new(@p1_response, @client)
        first_call = resp.next_page

        @client.unstub(:get_list) # Necessary because of https://github.com/freerange/mocha/issues/44
        @client.expects(:get_list).never
        second_call = resp.next_page
        assert_equal first_call, second_call
      end
    end

    describe "accessing previous page" do
      it "should allow accessing the previous page" do
        resp = GdsApi::ListResponse.new(@p2_response, @client)
        assert resp.has_previous_page?
        assert_equal %w(foo1 bar1), resp.previous_page['results']
      end

      it "should return nil with no previous page" do
        resp = GdsApi::ListResponse.new(@p1_response, @client)
        assert ! resp.has_previous_page?
        assert_equal nil, resp.previous_page
      end

      it "should memoize the previous_page" do
        resp = GdsApi::ListResponse.new(@p3_response, @client)
        first_call = resp.previous_page

        @client.unstub(:get_list) # Necessary because of https://github.com/freerange/mocha/issues/44
        @client.expects(:get_list).never
        second_call = resp.previous_page
        assert_equal first_call, second_call
      end
    end

    describe "accessing content across all pages" do
      before :each do
        @response = GdsApi::ListResponse.new(@p1_response, @client)
      end

      it "should allow iteration across multiple pages" do
        assert_equal 6, @response.with_subsequent_pages.count
        assert_equal %w(foo1 bar1 foo2 bar2 foo3 bar3), @response.with_subsequent_pages.to_a
        assert_equal %w(foo1 foo2 foo3), @response.with_subsequent_pages.select { |s| s =~ /foo/ }
      end

      it "should not load a page multiple times" do
        @client.unstub(:get_list) # Necessary because of https://github.com/freerange/mocha/issues/44
        @client.expects(:get_list).with("http://www.example.com/2").once.returns(GdsApi::ListResponse.new(@p2_response, @client))
        @client.expects(:get_list).with("http://www.example.com/3").once.returns(GdsApi::ListResponse.new(@p3_response, @client))

        3.times do
          @response.with_subsequent_pages.to_a
        end
      end

      it "should work with a non-paginated response" do
        data = {
          "results" => %w(foo1 bar1),
          "total" => 2,
          "_response_info" => {
            "status" => "ok",
          }
        }
        response = GdsApi::ListResponse.new(stub(body: data.to_json, status: 200, headers: {}), nil)

        assert_equal %w(foo1 bar1), response.with_subsequent_pages.to_a
      end
    end
  end
end
