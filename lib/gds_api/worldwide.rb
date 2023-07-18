require_relative "base"

class GdsApi::Worldwide < GdsApi::Base
  def world_locations
    get_list("#{base_url}/world-locations")
  end

  def world_location(location_slug)
    world_location = all_world_locations.find do |location|
      location.dig("details", "slug") == location_slug
    end

    raise GdsApi::HTTPNotFound, 404 unless world_location

    world_location
  end

  def organisations_for_world_location(location_slug)
    get_list("#{base_url}/world-locations/#{location_slug}/organisations")
  end

private

  def base_url
    "#{endpoint}/api"
  end

  def all_world_locations
    content_item = JSON.parse(get_raw("#{base_url}/content/world"))

    world_locations = format_locations(content_item.dig("details", "world_locations"), "World location")
    international_delegations = format_locations(content_item.dig("details", "international_delegations"), "International delegation")

    Array(world_locations) + Array(international_delegations)
  end

  def format_locations(locations, type)
    locations&.map do |location|
      {
        "id" => "#{Plek.new.website_root}/world/#{location['slug']}",
        "title" => location["name"],
        "format" => type,
        "updated_at" => location["updated_at"],
        "web_url" => "#{Plek.new.website_root}/world/#{location['slug']}",
        "analytics_identifier" => location["analytics_identifier"],
        "details" => {
          "slug" => location["slug"],
          "iso2" => location["iso2"],
        },
        "organisations" => {
          "id" => "#{Plek.new.website_root}/world/#{location['slug']}#organisations",
          "web_url" => "#{Plek.new.website_root}/world/#{location['slug']}#organisations",
        },
        "content_id" => location["content_id"],
      }
    end
  end
end
