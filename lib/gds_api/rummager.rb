require 'gds_api/search'

module GdsApi
  class Rummager < Search
    def initialize(*args)
      warn "GdsApi::Rummager is deprecated.  Use GdsApi::Search instead."
      super
    end
  end
end
