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
        content_id = options.fetch(:content_id)
        edition = content_hash(options)

        # This means that the get_content call made in
        # publishing_necessary? will describe the published edition,
        # and not a draft in case one has been left over (e.g. if
        # previously the SpecialRoutePublisher crashed before calling
        # publish).
        discard_draft_if_one_exists(content_id)

        if publishing_necessary?(content_id, edition)
          logger.info("Publishing #{edition[:type]} route #{edition[:base_path]}, routing to #{edition[:rendering_app]}")

          put_content_response = publishing_api.put_content(content_id, edition)
          publishing_api.publish(content_id)
        else
          put_content_response = nil
          logger.info("Skipping unnecessary publishing of #{edition[:base_path]}")
        end

        if patching_links_necessary?(content_id, options[:links])
          publishing_api.patch_links(content_id, links: options[:links])
        end

        put_content_response
      end

    private

      attr_reader :logger, :publishing_api

      def time
        (Time.respond_to?(:zone) && Time.zone) || Time
      end

      def discard_draft_if_one_exists(content_id)
        publishing_api.discard_draft(content_id)
      rescue HTTPNotFound
        nil # The draft didn't exist, so just continue
      end

      def publishing_necessary?(content_id, new_edition)
        begin
          current_edition_hash =
            publishing_api
              .get_content(content_id)
              .to_h
              .reject { |k, _v| k == 'content_id' }
        rescue HTTPNotFound
          return true
        end

        fields_which_differ = current_edition_hash.reject do |key, current_value|
          new_edition.fetch(key) == current_value
        end

        !fields_which_differ.empty?
      end

      def patching_links_necessary?(content_id, links)
        return false unless links

        begin
          existing_links =
            publishing_api
              .get_links(content_id)
              .to_h
              .fetch('links', {})
        rescue HTTPNotFound
          return true
        end

        differing_link_types = links.reject do |link_type, new_values|
          new_values.sort == existing_links.fetch(link_type.to_s, []).sort
        end

        if differing_link_types.empty?
          logger.info("Not updating links for #{content_id}, as there is no change")

          false
        else
          true
        end
      end

      def content_hash(options)
        {
          'base_path' => options.fetch(:base_path),
          'document_type' => options.fetch(:document_type, "special_route"),
          'schema_name' => options.fetch(:schema_name, "special_route"),
          'title' => options.fetch(:title),
          'description' => options.fetch(:description, ""),
          'locale' => "en",
          'details' => {},
          'routes' => [
            {
              'path' => options.fetch(:base_path),
              'type' => options.fetch(:type),
            }
          ],
          'publishing_app' => options.fetch(:publishing_app),
          'rendering_app' => options.fetch(:rendering_app),
          'public_updated_at' => time.now.iso8601,
          'update_type' => options.fetch(:update_type, "major")
        }
      end
    end
  end
end
