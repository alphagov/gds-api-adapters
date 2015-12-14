require 'test_helper'
require "gds_api/publishing_api/special_route_publisher"
require File.dirname(__FILE__) + '/../../lib/gds_api/test_helpers/publishing_api_v2'

describe GdsApi::PublishingApi::SpecialRoutePublisher do
  include ::GdsApi::TestHelpers::PublishingApiV2

  let(:content_id) { 'a-content-id-of-sorts' }  
  let(:special_route) {
    {
      content_id: content_id,
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
        publisher = GdsApi::PublishingApi::SpecialRoutePublisher.new
        endpoint = Plek.current.find('publishing-api')
        payload = {
          base_path: special_route[:base_path],
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
          public_updated_at: Time.now.iso8601,
        }

        stub_any_publishing_api_call
        
        publisher.publish(special_route)

        base_path = "#{endpoint}/v2/content/#{content_id}"
        assert_requested(:put, base_path, body: payload)
        assert_requested(:post, "#{base_path}/publish", body: { update_type: 'major' })

      end
    end

    describe 'Timezone handling' do
      let(:publishing_api) {
        stub(:publishing_api, put_content_item: nil)
      }
      let(:publisher) {
        GdsApi::PublishingApi::SpecialRoutePublisher.new(publishing_api: publishing_api)
      }

      it "is robust to Time.zone returning nil" do
        Timecop.freeze(Time.now) do
          Time.stubs(:zone).returns(nil)
          publishing_api.expects(:put_content).with(
            anything,
            has_entries(public_updated_at: Time.now.iso8601)
          )
          publishing_api.expects(:publish)

          publisher.publish(special_route)
        end
      end

      it "uses Time.zone if available" do
        Timecop.freeze(Time.now) do
          time_in_zone = stub("Time in zone", now: Time.parse("2010-01-01 10:10:10 +04:00"))
          Time.stubs(:zone).returns(time_in_zone)

          publishing_api.expects(:put_content).with(
            anything,
            has_entries(public_updated_at: time_in_zone.now.iso8601)
          )
          publishing_api.expects(:publish)

          publisher.publish(special_route)
        end
      end
    end
  end
end
