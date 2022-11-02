require "test_helper"
require "gds_api/publishing_api"

describe GdsApi::PublishingApi do
  let(:api_client) { GdsApi::PublishingApi.new(Plek.find("publishing-api")) }

  describe "content ID validation" do
    %i[get_content get_links get_linked_items discard_draft].each do |method|
      it "happens on #{method}" do
        assert_raises ArgumentError do
          api_client.send(method, nil)
        end
      end
    end

    it "happens on publish" do
      assert_raises ArgumentError do
        api_client.publish(nil, "major")
      end
    end

    it "happens on put_content" do
      assert_raises ArgumentError do
        api_client.put_content(nil, {})
      end
    end

    it "happens on patch_links" do
      assert_raises ArgumentError do
        api_client.patch_links(nil, links: {})
      end
    end
  end
end
