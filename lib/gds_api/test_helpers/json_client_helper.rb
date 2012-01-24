require 'gds_api/json_client'

module GdsApi
  module TestHelpers
    class NullCache
      def [](k)
        nil
      end

      def []=(k, v)
      end
    end
  end
end

GdsApi::JsonClient.cache = GdsApi::TestHelpers::NullCache.new
