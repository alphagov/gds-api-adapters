require 'gds_api/json_client'
require 'gds_api/null_cache'

GdsApi::JsonClient.cache = GdsApi::NullCache.new
