require "gds_api/test_helpers/publishing_api"

module GdsApi
  module TestHelpers
    module PublishingApiV2
      include PublishingApi

      def self.included(_base)
        warn "GdsApi::TestHelpers::PublishingApiV2 is deprecated.  Use GdsApi::TestHelpers::PublishingApi instead."
      end
    end
  end
end
