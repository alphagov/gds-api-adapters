require 'test_helper'
require "gds_api/publishing_api/special_route_publisher"

describe GdsApi::PublishingApi::SpecialRoutePublisher do
  let(:publishing_api) {
    stub(:publishing_api, put_content_item: nil)
  }

  let(:publisher) {
    GdsApi::PublishingApi::SpecialRoutePublisher.new(publishing_api: publishing_api)
  }

  let(:special_route) {
    {
      content_id: "a-content-id-of-sorts",
      title: "A title",
      description: "A description",
      base_path: "/favicon.ico",
      type: "exact",
      publishing_app: "static-publisher",
      rendering_app: "static-frontend",
    }
  }

  describe ".publish" do
    it "publishes the special routes" do
      Timecop.freeze(Time.now) do
        publishing_api.expects(:put_content_item).with(
          special_route[:base_path],
          {
            content_id: special_route[:content_id],
            format: "special_route",
            title: special_route[:title],
            description: special_route[:description],
            routes: [
              {
                path: special_route[:base_path],
                type: special_route[:type],
              }
            ],
            publishing_app: special_route[:publishing_app],
            rendering_app: special_route[:rendering_app],
            update_type: "major",
            public_updated_at: Time.now.iso8601,
          }
        )

        publisher.publish(special_route)
      end
    end

    it "is robust to Time.zone returning nil" do
      Timecop.freeze(Time.now) do
        Time.stubs(:zone).returns(nil)

        publishing_api.expects(:put_content_item).with(
          anything,
          has_entries(public_updated_at: Time.now.iso8601)
        )

        publisher.publish(special_route)
      end
    end

    it "uses Time.zone if available" do
      Timecop.freeze(Time.now) do
        time_in_zone = stub("Time in zone", now: Time.parse("2010-01-01 10:10:10 +04:00"))
        Time.stubs(:zone).returns(time_in_zone)

        publishing_api.expects(:put_content_item).with(
          anything,
          has_entries(public_updated_at: time_in_zone.now.iso8601)
        )

        publisher.publish(special_route)
      end
    end
  end
end
