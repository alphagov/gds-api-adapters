require 'gds_api/publisher'
require 'gds_api/imminence'
require 'gds_api/panopticon'
require 'gds_api/content_api'
require 'gds_api/licence_application'

module GdsApi
  module Helpers
    def content_api
      @content_api ||= GdsApi::ContentApi.new(Plek.current.environment)
    end

    def publisher_api
      @api ||= GdsApi::Publisher.new(Plek.current.environment)
    end

    def imminence_api
      @imminence_api ||= GdsApi::Imminence.new(Plek.current.environment)
    end

    def licence_application_api
      options = (ENV['LICENCE_USER'] and ENV['LICENCE_PASSWORD']) ? { basic_auth: { user: ENV['LICENCE_USER'], password: ENV['LICENCE_PASSWORD'] }} : { }
      @licence_application_api ||= GdsApi::LicenceApplication.new(ENV["LICENCE_ENV"] || Plek.current.environment, options)
    end

    def panopticon_api
      @panopticon_api ||= GdsApi::Panopticon.new(Plek.current.environment, panopticon_api_credentials)
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
