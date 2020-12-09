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

        update_type = options.fetch(:update_type, "major")
        locale = options.fetch(:locale, "en")

        put_content_response = publishing_api.put_content(
          options.fetch(:content_id),
          base_path: options.fetch(:base_path),
          document_type: options.fetch(:document_type, "special_route"),
          schema_name: options.fetch(:schema_name, "special_route"),
          title: options.fetch(:title),
          description: options.fetch(:description, ""),
          locale: locale,
          details: {},
          routes: [
            {
              path: options.fetch(:base_path),
              type: options.fetch(:type),
            },
          ],
          publishing_app: options.fetch(:publishing_app),
          rendering_app: options.fetch(:rendering_app),
          public_updated_at: time.now.iso8601,
          update_type: update_type,
        )

        publishing_api.patch_links(options.fetch(:content_id), links: options[:links]) if options[:links]
        publishing_api.publish(options.fetch(:content_id), update_type, locale: locale)
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
