require 'test_helper'
require "gds_api/publishing_api/special_route_publisher"
require "govuk-content-schema-test-helpers"
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
      publishing_app: "static",
      rendering_app: "static",
    }
  }

  let(:publisher) { GdsApi::PublishingApi::SpecialRoutePublisher.new }
  let(:endpoint) { Plek.current.find('publishing-api') }

  describe ".publish" do
    before do
      stub_any_publishing_api_call
    end

    it "publishes valid special routes" do
      Timecop.freeze(Time.now) do
        publisher.publish(special_route)

        expected_payload = {
          base_path: special_route[:base_path],
          document_type: "special_route",
          schema_name: "special_route",
          title: special_route[:title],
          description: special_route[:description],
          routes: [
            {
              path: special_route[:base_path],
              type: special_route[:type],
            }
          ],
          locale: "en",
          details: {},
          publishing_app: special_route[:publishing_app],
          rendering_app: special_route[:rendering_app],
          public_updated_at: Time.now.iso8601,
          update_type: "major",
        }

        assert_requested(:put, "#{endpoint}/v2/content/#{content_id}", body: expected_payload)
        assert_valid_special_route(expected_payload)
        assert_publishing_api_publish(content_id)
      end
    end

    it "publishes customized document type" do
      publisher.publish(special_route.merge(document_type: "other_document_type"))

      assert_requested(:put, "#{endpoint}/v2/content/#{content_id}") do |req|
        JSON.parse(req.body)["document_type"] == "other_document_type"
      end
      assert_publishing_api_publish(content_id)
    end

    it "publishes customized schema_name" do
      publisher.publish(special_route.merge(schema_name: "dummy_schema"))

      assert_requested(:put, "#{endpoint}/v2/content/#{content_id}") do |req|
        JSON.parse(req.body)["schema_name"] == "dummy_schema"
      end
    end

    it "publishes links" do
      links = {
        links: {
          organisations: %w[org-content-id]
        }
      }

      publisher.publish(special_route.merge(links))

      assert_requested(:patch, "#{endpoint}/v2/links/#{content_id}", body: links)
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

  def assert_valid_special_route(payload)
    validator = GovukContentSchemaTestHelpers::Validator.new(
      "special_route",
      "schema",
      payload
    )

    assert validator.valid?, validator.errors.join("\n")
  end
end
