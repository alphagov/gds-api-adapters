require 'gds_api/base'
require 'rack/utils'

module GdsApi
  class FactCave < Base

    def fact_for_slug(slug)
      return "" if slug.nil? || slug == ""
      get_json!("#{base_url}/facts/#{slug}")
    end

  private

    def base_url
      endpoint
    end
  end
end
