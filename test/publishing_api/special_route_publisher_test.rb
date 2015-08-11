require 'test_helper'
require "gds_api/publishing_api/special_route_publisher"

describe GdsApi::PublishingApi::SpecialRoutePublisher do
  let(:publishing_api) {
    stub(:publishing_api)
  }

  let(:publisher) {
    GdsApi::PublishingApi::SpecialRoutePublisher.new(publishing_api: publishing_api)
  }

  describe ".publish" do
    it "publishes the special routes" do
      publishing_api.expects(:put_content_item).with(
        "/favicon.ico",
        {
          content_id: "a-content-id-of-sorts",
          format: "special_route",
          title: "A title",
          description: "A description",
          routes: [
            {
              path: "/favicon.ico",
              type: "exact",
            }
          ],
          publishing_app: "static-publisher",
          rendering_app: "static-frontend",
          update_type: "major",
          public_updated_at: Time.now.iso8601,
        }
      )

      publisher.publish(
        content_id: "a-content-id-of-sorts",
        title: "A title",
        description: "A description",
        base_path: "/favicon.ico",
        type: "exact",
        publishing_app: "static-publisher",
        rendering_app: "static-frontend",
      )
    end
  end
end
