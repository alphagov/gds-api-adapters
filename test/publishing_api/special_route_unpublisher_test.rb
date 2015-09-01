require 'test_helper'
require "gds_api/publishing_api/special_route_unpublisher"

describe GdsApi::PublishingApi::SpecialRouteUnpublisher do
  let(:publishing_api) {
    stub(:publishing_api, put_content_item: nil)
  }

  let(:unpublisher) {
    GdsApi::PublishingApi::SpecialRouteUnpublisher.new(publishing_api: publishing_api)
  }

  let(:special_route) {
    {
      content_id: "a-content-id-of-sorts",
      base_path: "/favicon.ico",
      type: "prefix",
      publishing_app: "static-publisher",
      routes: [
        {path: "/favicon.ico", type: "exact"},
      ],
    }
  }

  describe ".publish" do
    it "unpublishes the special routes" do

      publishing_api.expects(:put_content_item).with(
        special_route[:base_path],
        {
          content_id: special_route[:content_id],
          format: "gone",
          routes: [
            {
              path: special_route[:base_path],
              type: special_route[:type],
            }
          ],
          publishing_app: special_route[:publishing_app],
          update_type: "major",
        }
      )

      unpublisher.unpublish(special_route)

    end
  end
end
