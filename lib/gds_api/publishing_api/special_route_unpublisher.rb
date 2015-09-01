require "gds_api/publishing_api"

module GdsApi
  class PublishingApi < GdsApi::Base
    class SpecialRouteUnpublisher
      def initialize(options = {})
        @logger = options[:logger] || GdsApi::Base.logger
        @publishing_api = options[:publishing_api] || GdsApi::PublishingApi.new(Plek.find("publishing-api"))
      end

      def unpublish(options)
        logger.info("Unpublishing #{options.fetch(:type)} route #{options.fetch(:base_path)}")

        publishing_api.put_content_item(options.fetch(:base_path), {
          content_id: options.fetch(:content_id),
          format: "gone",
          update_type: "major",
          publishing_app: options.fetch(:publishing_app),
          routes: [
            {
              path: options.fetch(:base_path),
              type: options.fetch(:type),
            }
          ],
        })
      end

    private
      attr_reader :logger, :publishing_api

    end
  end
end
