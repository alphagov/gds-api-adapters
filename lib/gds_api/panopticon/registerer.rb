module GdsApi
  class Panopticon < GdsApi::Base
    class Registerer
      attr_accessor :logger, :owning_app, :kind

      def initialize(options)
        @logger = options[:logger] || GdsApi::Base.logger
        @owning_app = options[:owning_app]
        @kind = options[:kind] || 'custom-application'
        @panopticon = options[:panopticon]
        @platform = options[:platform] || ENV['FACTER_govuk_platform'] || 'development'
      end

      def record_to_artefact(record)
        hash = {
          slug: record.slug,
          owning_app: owning_app,
          kind: kind,
          name: record.title,
          description: record.description,
          live: record.live
        }
        [:need_id, :section, :indexable_content].each do |attr_name|
          if record.respond_to? attr_name
            hash[attr_name] = record.send(attr_name)
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
          timeout: 5
        }
        @panopticon ||= GdsApi::Panopticon.new(@platform, options.merge(panopticon_api_credentials))
      end

      def panopticon_api_credentials
        Object::const_defined?(:PANOPTICON_API_CREDENTIALS) ? PANOPTICON_API_CREDENTIALS : {}
      end
    end
  end
end