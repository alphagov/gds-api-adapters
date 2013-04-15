require 'gds_api/json_client'

module GdsApi
  module TestHelpers
    class NullCache
      def [](k)
        nil
      end

      def []=(k, v)
      end

      def store(k, v, args={})
      end
    end
  end
end

GdsApi::JsonClient.cache = GdsApi::TestHelpers::NullCache.new
