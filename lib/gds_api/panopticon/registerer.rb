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
        hash = {slug: record.slug, owning_app: owning_app, kind: kind, name: record.title}
        if record.respond_to? :need_id
          hash[:need_id] = record.need_id
        end
        hash
      end
  
      # record should respond to #slug and #title, or override #record_to_artefact 
      def register(record)
        register_artefact(record_to_artefact(record))
      end
  
    protected
  
      def register_artefact(artefact)
        logger.info "Checking #{artefact[:slug]}"
        existing = panopticon.artefact_for_slug(artefact[:slug])
        if ! existing
          logger.info "Creating #{artefact[:slug]}"
          panopticon.create_artefact(artefact)
        elsif existing.owning_app == artefact[:owning_app]
          logger.info "Updating #{artefact[:slug]}"
          panopticon.update_artefact(artefact[:slug], artefact)
        else
          raise "Slug #{artefact[:slug]} already registered to application '#{existing.owning_app}'"
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