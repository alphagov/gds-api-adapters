require 'gds_api/publisher'
require 'gds_api/imminence'
require 'gds_api/panopticon'
require 'gds_api/content_api'

module GdsApi
  module Helpers
    def publisher_api
      @_publisher_api ||= GdsApi::Publisher.new(Plek.current.environment)
    end

    def imminence_api
      @_imminence_api ||= GdsApi::Imminence.new(Plek.current.environment)
    end

    def content_api
      @_content_api ||= GdsApi::ContentApi.new(Plek.current.environment, api_credentials)
    end

    def panopticon_api
      @_panopticon_api ||= GdsApi::PanopticonApi.new(Plek.current.environment, api_credentials)
    end

    def api_credentials
      # TODO The name of the constant should be changed, 
      # but that requires acrobatics with alphagov-deployment, 
      # and will likely change with OAuth API auth anyway
      Object::const_defined?(:PANOPTICON_API_CREDENTIALS) ? PANOPTICON_API_CREDENTIALS : {}
    end

    def fetch_artefact(params)
      content_api.artefact_for_slug(params[:slug]) || OpenStruct.new(section: 'missing', need_id: 'missing', kind: 'missing')
    end

    def self.included(klass)
      if klass.respond_to?(:helper_method)
        klass.helper_method :publisher_api, :panopticon_api, :content_api, :imminence_api
      end
    end
  end
end
