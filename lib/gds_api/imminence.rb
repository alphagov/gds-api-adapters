require_relative 'base'

class GdsApi::Imminence < GdsApi::Base

  def api_url(type, params)
    vals = [:limit, :lat, :lng, :postcode].select{ |p| params.include? p }
    querystring = URI.encode_www_form vals.map { |p| [p, params[p]] }
    "#{@endpoint}/places/#{type}.json?#{querystring}"
  end

  def places(type, lat, lon, limit=5)
    url = api_url(type, lat: lat, lng: lon, limit: limit)
    places = get_json(url) || []
    places.map { |p| self.class.parse_place_hash(p) }
  end

  def places_for_postcode(type, postcode, limit=5)
    url = api_url(type, postcode: postcode, limit: limit)
    places = get_json(url) || []
    places.map { |p| self.class.parse_place_hash(p) }
  end

  def self.parse_place_hash(place_hash)
    location = self.extract_location_hash(place_hash["location"])
    address = self.extract_address_hash(place_hash)

    place_hash.merge(location).merge(address)
  end

  def places_kml(type)
    get_raw("#{@endpoint}/places/#{type}.kml").body
  end

  def business_support_schemes(facets_hash)
    query = facets_hash.keys.sort.map { |k| "#{k.to_s}=#{facets_hash[k]}" }.join("&")
    query = "?#{query}" unless query.empty?
    get_json!("#{@endpoint}/business_support_schemes.json#{query}")
  end

  def areas_for_postcode(postcode)
    url = "#{@endpoint}/areas/#{URI.encode(postcode)}.json"
    get_json(url)
  end

  def areas_for_type(type)
    url = "#{@endpoint}/areas/#{type}.json"
    get_json(url)
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
