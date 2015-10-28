require_relative 'base'
require_relative 'exceptions'

class GdsApi::Mapit < GdsApi::Base

  def location_for_postcode(postcode)
    response = get_json!("#{base_url}/postcode/#{CGI.escape postcode}.json")
    Location.new(response)

  rescue GdsApi::HTTPNotFound => e
    # allow 404 errors, as these will be valid postcodes with no match in Mapit
    e
  rescue GdsApi::HTTPErrorResponse => e
    # allow 400 errors, as they can be invalid postcodes people have entered
    e
  end

  def areas_for_type(type)
    get_json("#{base_url}/areas/#{type}.json")
  end

  class Location
    attr_reader :response

    def initialize(response)
      @response = response
    end

    def lat
      @response['wgs84_lat']
    end

    def lon
      @response['wgs84_lon']
    end

    def areas
      @response['areas'].map {|i, area| OpenStruct.new(area) }
    end

    def postcode
      @response['postcode']
    end
  end

  private
    def base_url
      endpoint
    end

end
