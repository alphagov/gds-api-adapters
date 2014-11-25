require 'plek'

module GdsApi
  class Panopticon < GdsApi::Base
    class Registerer
      attr_accessor :logger, :owning_app, :rendering_app, :kind

      def initialize(options)
        @logger = options[:logger] || GdsApi::Base.logger
        @owning_app = options[:owning_app]
        @rendering_app = options[:rendering_app]
        @kind = options[:kind] || 'custom-application'
        @panopticon = options[:panopticon]
        @endpoint_url = options[:endpoint_url] || Plek.current.find("panopticon")
        @timeout = options[:timeout] || 10
      end

      def record_to_artefact(record)
        hash = {
          slug: record.slug,
          owning_app: owning_app,
          kind: kind,
          name: record.title,
          description: record.description,
          state: record.state
        }

        if rendering_app
          hash[:rendering_app] = rendering_app
        end

        optional_params = [
          :need_id,
          :need_ids,

          :section,
          :primary_section,
          :sections,

          :paths,
          :prefixes,

          :specialist_sectors,
          :organisation_ids,
          :indexable_content,
        ]

        deprecated_params = {
          section: [:primary_section, :sections]
        }

        deprecated_params.each do |attr_name, replacements|
          if record.respond_to?(attr_name)
            replacements = Array(replacements)
            logger.warn "#{attr_name} has been deprecated in favour of #{replacements.join(' and ')}"
          end
        end

        optional_params.each do |attr_name|
          if record.respond_to? attr_name
            hash[attr_name] = record.public_send(attr_name)
          end
        end

        hash
      end

      # record should respond to #slug and #title, or override #record_to_artefact
      def register(record)
        register_artefact(record_to_artefact(record))
      end

    protected

      def register_artefact(artefact)
        logger.info "Putting #{artefact[:slug]}"

        # Error responses here are pretty fatal, so propagate them
        response = panopticon.put_artefact!(artefact[:slug], artefact)
        case response.code
        when 200
          logger.info "Updated #{artefact[:slug]}"
        when 201
          logger.info "Created #{artefact[:slug]}"
        else
          # Only expect 200 or 201 success codes, but best to have a fallback
          logger.info "Registered #{artefact[:slug]} (code #{response.code})"
        end
      end

      def panopticon
        options = {
          timeout: @timeout
        }
        @panopticon ||= GdsApi::Panopticon.new(@endpoint_url, options.merge(panopticon_api_credentials))
      end

      def panopticon_api_credentials
        Object::const_defined?(:PANOPTICON_API_CREDENTIALS) ? PANOPTICON_API_CREDENTIALS : {}
      end
    end
  end
end
