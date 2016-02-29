require "gds_api/publishing_api_v2"
require "time"

module GdsApi
  class PublishingApi < GdsApi::Base
    class SpecialRoutePublisher
      def initialize(options = {})
        @logger = options[:logger] || GdsApi::Base.logger
        @publishing_api = options[:publishing_api] || GdsApi::PublishingApiV2.new(Plek.find("publishing-api"))
      end

      def publish(options)
        logger.info("Publishing #{options.fetch(:type)} route #{options.fetch(:base_path)}, routing to #{options.fetch(:rendering_app)}")

        put_content_response = publishing_api.put_content(options.fetch(:content_id), {
          base_path: options.fetch(:base_path),
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
          public_updated_at: time.now.iso8601,
        })
        publishing_api.patch_links(options.fetch(:content_id), links: options[:links]) if options[:links]
        publishing_api.publish(options.fetch(:content_id), 'major')
        put_content_response
      end

    private
      attr_reader :logger, :publishing_api

      def time
        (Time.respond_to?(:zone) && Time.zone) || Time
      end
    end
  end
end
