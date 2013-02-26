require 'gds_api/publisher'
require 'gds_api/imminence'
require 'gds_api/panopticon'
require 'gds_api/content_api'
require 'gds_api/licence_application'
require 'gds_api/asset_manager'

module GdsApi
  module Helpers
    def asset_manager_api
      @asset_manager_api ||= GdsApi::AssetManager.new(Plek.current.find('asset-manager'))
    end

    def content_api
      @content_api ||= GdsApi::ContentApi.new(Plek.current.find("contentapi"))
    end

    def publisher_api
      @api ||= GdsApi::Publisher.new(Plek.current.find("publisher"))
    end

    def imminence_api
      @imminence_api ||= GdsApi::Imminence.new(Plek.current.find("imminence"))
    end

    def licence_application_api
      @licence_application_api ||= GdsApi::LicenceApplication.new(Plek.current.find("licensify"))
    end

    def panopticon_api
      @panopticon_api ||= GdsApi::Panopticon.new(Plek.current.find("panopticon"), panopticon_api_credentials)
    end

    def panopticon_api_credentials
      Object::const_defined?(:PANOPTICON_API_CREDENTIALS) ? PANOPTICON_API_CREDENTIALS : {}
    end

    def self.included(klass)
      if klass.respond_to?(:helper_method)
        klass.helper_method :publisher_api, :panopticon_api, :imminence_api, :content_api, :licence_application_api
      end
    end
  end
end
