require_relative "base"

class GdsApi::Worldwide < GdsApi::Base
  def world_locations
    all_world_locations
  end

  def world_location(location_slug)
    world_location = all_world_locations.find do |location|
      location.dig("details", "slug") == location_slug
    end

    raise GdsApi::HTTPNotFound, 404 unless world_location

    world_location
  end

  def organisations_for_world_location(location_slug)
    worldwide_organisations = worldwide_organisations_for_location(location_slug)

    worldwide_organisations.map do |organisation|
      worldwide_organisation(organisation["link"])
    end
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

  def worldwide_organisations_for_location(world_location)
    search_results = JSON.parse(get_raw("#{base_url}/search.json?filter_format=worldwide_organisation&filter_world_locations=#{world_location}"))

    search_results["results"]
  end

  def worldwide_organisation(path)
    content_item = JSON.parse(get_raw("#{base_url}/content#{path}"))

    {
      "id" => "#{Plek.new.website_root}#{path}",
      "title" => content_item["title"],
      "format" => "Worldwide Organisation",
      "updated_at" => content_item["updated_at"],
      "web_url" => "#{Plek.new.website_root}#{path}",
      "details" => {
        "slug" => path.gsub("/world/organisations/", ""),
      },
      "analytics_identifier" => content_item["analytics_identifier"],
      "offices" => {
        "main" => format_office(content_item.dig("links", "main_office", 0)),
        "other" => content_item.dig("links", "home_page_offices")&.map do |office|
                     format_office(office)
                   end || [],
      },
      "sponsors" => content_item.dig("links", "sponsoring_organisations")&.map do |sponsor|
                      format_sponsor(sponsor)
                    end || [],
    }
  end

  def format_office(office)
    return {} unless office

    contact = office.dig("links", "contact", 0)

    {
      "title" => office["title"],
      "format" => "World Office",
      "updated_at" => office["public_updated_at"],
      "web_url" => office["web_url"],
      "details" => {
        "email" => contact&.dig("details", "email_addresses"),
        "description" => contact&.dig("details", "description"),
        "contact_form_url" => contact&.dig("details", "contact_form_links"),
        "access_and_opening_times" => office.dig("details", "access_and_opening_times"),
        "type" => office.dig("details", "type"),
      },
      "address" => {
        "adr" => {
          "fn" => contact&.dig("details", "post_addresses", 0, "title"),
          "street-address" => contact&.dig("details", "post_addresses", 0, "street_address"),
          "postal-code" => contact&.dig("details", "post_addresses", 0, "postal_code"),
          "locality" => contact&.dig("details", "post_addresses", 0, "locality"),
          "region" => contact&.dig("details", "post_addresses", 0, "region"),
          "country-name" => contact&.dig("details", "post_addresses", 0, "world_location"),
        },
      },
      "contact_numbers" => contact&.dig("details", "phone_numbers")&.map do |phone_number|
        {
          "label" => phone_number["title"],
          "number" => phone_number["number"],
        }
      end,
      "services" => contact&.dig("details", "services")&.map do |service|
        {
          title: service["title"],
          type: service["type"],
        }
      end,
    }
  end

  def format_sponsor(sponsor)
    {
      "title" => sponsor["title"],
      "web_url" => sponsor["web_url"],
      "details" => {
        "acronym" => sponsor.dig("details", "acronym"),
      },
    }
  end
end
