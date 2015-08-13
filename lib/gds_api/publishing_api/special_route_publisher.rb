require "gds_api/publishing_api"
require "time"

module GdsApi
  class PublishingApi < GdsApi::Base
    class SpecialRoutePublisher
      def initialize(options = {})
        @logger = options[:logger] || GdsApi::Base.logger
        @publishing_api = options[:publishing_api] || GdsApi::PublishingApi.new(Plek.find("publishing-api"))
      end

      def publish(options)
        logger.info("Publishing #{options.fetch(:type)} route #{options.fetch(:base_path)}, routing to #{options.fetch(:rendering_app)}")

        publishing_api.put_content_item(options.fetch(:base_path), {
          content_id: options.fetch(:content_id),
          format: "special_route",
          title: options.fetch(:title),
          description: options[:description] || "",
          routes: [
            {
              path: options.fetch(:base_path),
              type: options.fetch(:type),
            }
          ],
          publishing_app: options.fetch(:publishing_app),
          rendering_app: options.fetch(:rendering_app),
          update_type: "major",
          public_updated_at: time.now.iso8601,
        })
      end

    private
      attr_reader :logger, :publishing_api

      def time
        (Time.respond_to?(:zone) && Time.zone) || Time
      end
    end
  end
end
