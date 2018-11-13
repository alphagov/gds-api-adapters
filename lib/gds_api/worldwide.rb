require_relative 'base'

class GdsApi::Worldwide < GdsApi::Base
  def world_locations(options = { page: 1 })
    get_list("#{base_url}/world-locations?page=#{options[:page]}")
  end

  def world_location(location_slug)
    get_json("#{base_url}/world-locations/#{location_slug}")
  end

  def organisations_for_world_location(location_slug)
    get_list("#{base_url}/world-locations/#{location_slug}/organisations")
  end

private

  def base_url
    "#{endpoint}/api"
  end
end
