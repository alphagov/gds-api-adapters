require "gds_api/test_helpers/json_client_helper"
require "gds_api/test_helpers/content_item_helpers"
require "gds_api/test_helpers/intent_helpers"
require "json"

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
