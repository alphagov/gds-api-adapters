require 'gds_api/base'

module GdsApi
  class FactCave < Base

    def fact(slug)
      return nil if slug.nil? || slug == ""
      get_json("#{endpoint}/facts/#{slug}")
    end

  end
end
