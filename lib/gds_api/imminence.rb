require_relative 'base'

class GdsApi::Imminence < GdsApi::Base

  def api_url(type, lat, lon, limit=5)
    "#{@endpoint}/places/#{type}.json?limit=#{limit}&lat=#{lat}&lng=#{lon}"
  end

  def places(type, lat, lon, limit=5)
    places = get_json(api_url(type, lat, lon, limit)) || []
    places.map { |p| self.class.parse_place_hash(p) }
  end

  def self.parse_place_hash(place_hash)
    location = self.extract_location_hash(place_hash["location"])
    address = self.extract_address_hash(place_hash)

    place_hash.merge(location).merge(address)
  end

  def places_kml(type)
    get_raw("#{@endpoint}/places/#{type}.kml")
  end

private
  def self.extract_location_hash(location)
    # Deal with all known location formats:
    #   Old style: [latitude, longitude]; empty array for no location
    #   New style: hash with keys "longitude", "latitude"; nil for no location
    case location
    when Array
      {"latitude" => location[0], "longitude" => location[1]}
    when Hash
      location
    when nil
      {"latitude" => nil, "longitude" => nil}
    end
  end

  def self.extract_address_hash(place_hash)
    address_fields = [
      place_hash["address1"],
      place_hash["address2"]
    ].reject { |a| a.nil? or a == "" }
    {"address" => address_fields.map(&:strip).join(", ")}
  end


end
