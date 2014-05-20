require_relative 'base'
require_relative 'exceptions'

class GdsApi::Mapit < GdsApi::Base
  include GdsApi::ExceptionHandling

  def location_for_postcode(postcode)
    response = get_json("#{base_url}/postcode/#{CGI.escape postcode}.json")
    return Location.new(response) unless response.nil?
  rescue GdsApi::HTTPErrorResponse => e
    # allow 400 errors, as they can be invalid postcodes people have entered
    raise GdsApi::HTTPErrorResponse.new(e.code) unless e.code == 400
  end

  def areas_for_type(type)
    response = get_json("#{base_url}/areas/#{type}.json")
    return areas_from_response(response)
  end

  class Area
    def initialize(hash)
      [:id, :name, :country_name].each do |attr|
        self.class.send(:attr_reader, attr)
        instance_variable_set("@#{attr}", hash[attr.to_s])
      end
    end
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

    def areas_from_response(response)
      [].tap do |ary|
        response.each do |k,v|
          ary << Area.new(v)
        end
      end
    end
end
