require 'test_helper'
require 'gds_api/content_store'
require 'gds_api/test_helpers/content_store'

describe GdsApi::ContentStore do
  include GdsApi::TestHelpers::ContentStore

  before do
    @base_api_url = Plek.current.find("content-store")
    @api = GdsApi::ContentStore.new(@base_api_url)
  end

  describe "#content_item" do
    it "returns the item" do
      base_path = "/test-from-content-store"
      stub_content_store_has_item(base_path)

      response = @api.content_item(base_path)

      assert_equal base_path, response["base_path"]
    end

    it "raises if the item doesn't exist" do
      stub_content_store_does_not_have_item("/non-existent")

      assert_raises(GdsApi::HTTPNotFound) do
        @api.content_item("/non-existent")
      end
    end

    it "raises if the item doesn't exist" do
      stub_content_store_does_not_have_item("/non-existent")

      assert_raises GdsApi::HTTPNotFound do
        @api.content_item("/non-existent")
      end
    end

    it "raises if the item is gone" do
      stub_content_store_has_gone_item("/it-is-gone")

      assert_raises(GdsApi::HTTPGone) do
        @api.content_item("/it-is-gone")
      end
    end

    it "raises if the item is gone" do
      stub_content_store_has_gone_item("/it-is-gone")

      assert_raises GdsApi::HTTPGone do
        @api.content_item("/it-is-gone")
      end
    end
  end

  describe ".redirect_for_path" do
    before do
      @content_item = content_item_for_base_path("/test").merge("redirects" => [])
    end

    def create_redirect(
      path:,
      destination: "/destination",
      type: "exact",
      segments_mode: "ignore",
      redirect_type: "permanent"
    )
      {
        "path" => path,
        "destination" => destination,
        "type" => type,
        "segments_mode" => segments_mode,
        "redirect_type" => redirect_type,
      }
    end

    it "raises when there are no redirects on the content item" do
      @content_item["redirects"] = []

      assert_raises GdsApi::ContentStore::UnresolvedRedirect do
        GdsApi::ContentStore.redirect_for_path(@content_item, "/test")
      end
    end

    it "raises when no redirects match the request path" do
      @content_item["redirects"] = [
        create_redirect(path: "/not-going-to-match")
      ]

      assert_raises GdsApi::ContentStore::UnresolvedRedirect do
        GdsApi::ContentStore.redirect_for_path(@content_item, "/test")
      end
    end

    it "creates an absolute URL when a redirect redirects internally" do
      @content_item["redirects"] = [
        create_redirect(path: "/a", destination: "/b")
      ]

      destination, = GdsApi::ContentStore.redirect_for_path(@content_item, "/a")
      assert_equal "http://www.dev.gov.uk/b", destination
    end

    it "returns an absolute URL redirect unmodified" do
      @content_item["redirects"] = [
        create_redirect(path: "/a", destination: "https://example.com/b")
      ]

      destination, = GdsApi::ContentStore.redirect_for_path(@content_item, "/a")
      assert_equal "https://example.com/b", destination
    end

    it "includes a 301 status code for a permanent redirect" do
      @content_item["redirects"] = [
        create_redirect(path: "/a", redirect_type: "permanent")
      ]

      _, status_code = GdsApi::ContentStore.redirect_for_path(@content_item, "/a")
      assert_equal 301, status_code
    end

    it "includes a 301 status code for a temporary redirect" do
      @content_item["redirects"] = [
        create_redirect(path: "/a", redirect_type: "temporary")
      ]

      _, status_code = GdsApi::ContentStore.redirect_for_path(@content_item, "/a")
      assert_equal 302, status_code
    end

    it "returns an absolute URL redirect unmodified" do
      @content_item["redirects"] = [
        create_redirect(path: "/a", destination: "https://example.com/b")
      ]

      destination, = GdsApi::ContentStore.redirect_for_path(@content_item, "/a")
      assert_equal "https://example.com/b", destination
    end

    describe "when a redirect has segment_mode ignore" do
      it "ignores query string for an exact route" do
        @content_item["redirects"] = [
          create_redirect(path: "/a", destination: "/b", segments_mode: "ignore")
        ]

        destination, = GdsApi::ContentStore.redirect_for_path(@content_item, "/a", "query=1")
        assert_equal "http://www.dev.gov.uk/b", destination
      end

      it "ignores segments for a prefix route" do
        @content_item["redirects"] = [
          create_redirect(
            path: "/a", destination: "/b", segments_mode: "ignore", type: "prefix"
          )
        ]

        destination, = GdsApi::ContentStore.redirect_for_path(@content_item, "/a/b")
        assert_equal "http://www.dev.gov.uk/b", destination
      end
    end

    describe "when a redirect has segment_mode preserve" do
      it "maintains a query string for an exact route" do
        @content_item["redirects"] = [
          create_redirect(path: "/a", destination: "/b", segments_mode: "preserve")
        ]

        destination, = GdsApi::ContentStore.redirect_for_path(@content_item, "/a", "query=1")
        assert_equal "http://www.dev.gov.uk/b?query=1", destination
      end

      it "maintains segments for a prefix route" do
        @content_item["redirects"] = [
          create_redirect(
            path: "/path", destination: "/destination", segments_mode: "preserve", type: "prefix"
          )
        ]

        destination, = GdsApi::ContentStore.redirect_for_path(@content_item, "/path/segment", "query=0")
        assert_equal "http://www.dev.gov.uk/destination/segment?query=0", destination
      end

      it "maintains segments for an absolute prefix route" do
        @content_item["redirects"] = [
          create_redirect(
            path: "/path", destination: "http://example.com/destination", segments_mode: "preserve", type: "prefix"
          )
        ]

        destination, = GdsApi::ContentStore.redirect_for_path(@content_item, "/path/segment")
        assert_equal "http://example.com/destination/segment", destination
      end
    end

    it "matches identical path in multiple exact redirects" do
      @content_item["redirects"] = [
        create_redirect(path: "/a", destination: "/x", type: "exact"),
        create_redirect(path: "/a/b", destination: "/x/y", type: "exact"),
      ]

      destination, = GdsApi::ContentStore.redirect_for_path(@content_item, "/a/b")
      assert_equal "http://www.dev.gov.uk/x/y", destination
    end

    it "matches most relevant in multiple prefix matches" do
      @content_item["redirects"] = [
        create_redirect(path: "/a", destination: "/x", type: "prefix", segments_mode: "preserve"),
        create_redirect(path: "/a/b", destination: "/x/y", type: "prefix", segments_mode: "preserve"),
      ]

      destination, = GdsApi::ContentStore.redirect_for_path(@content_item, "/a/b/c")
      assert_equal "http://www.dev.gov.uk/x/y/c", destination
    end
  end
end
