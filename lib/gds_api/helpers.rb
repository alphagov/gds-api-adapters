require 'gds_api/publisher'
require 'gds_api/imminence'
require 'gds_api/panopticon'

module GdsApi
  module Helpers
    def publisher_api
      @api ||= GdsApi::Publisher.new(Plek.current.environment)
    end

    def imminence_api
      @imminence_api ||= GdsApi::Imminence.new(Plek.current.environment)
    end

    def panopticon_api
      @panopticon_api ||= GdsApi::Panopticon.new(Plek.current.environment)
    end
    
    def self.included(klass)
      if klass.respond_to?(:helper_method)
        klass.helper_method :publisher_api, :panopticon_api, :imminence_api
      end
    end
  end
end
