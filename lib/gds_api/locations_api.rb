require_relative "base"
require_relative "exceptions"

class GdsApi::LocationsApi < GdsApi::Base
  # Get a list of local custodian codes for a postcode
  #
  # @param [String, nil] postcode The postcode for which the custodian codes are requested
  #
  # @return [Array] All local custodian codes for a specific postcode
  def local_custodian_code_for_postcode(postcode)
    response = get_json("#{endpoint}/v1/locations?postcode=#{postcode}")

    return [] if response["results"].nil?

    response["results"].map { |r| r["local_custodian_code"] }.uniq
  end

  # Get the average coordinates for a postcode
  #
  # @param [String, nil] postcode The postcode for which the coordinates are requested
  #
  # @return [Hash] The average coordinates (two fields, "latitude" and "longitude") for a specific postcode
  def coordinates_for_postcode(postcode)
    response = get_json("#{endpoint}/v1/locations?postcode=#{postcode}")

    { "latitude" => response["average_latitude"], "longitude" => response["average_longitude"] } unless response["results"].nil?
  end

  # Get all results for a postcode
  #
  # @param [String, nil] postcode The postcode for which results are requested
  #
  # @return [Hash] The fulls results as returned from Locations API, with the average latitude
  # and longitude, and an array of results for individual addresses with lat/long/lcc, eg:
  #  {
  #  "average_latitude"=>51.43122412857143,
  # "average_longitude"=>-0.37395367142857144,
  # "results"=>
  #  [{"address"=>"29, DEAN ROAD, HAMPTON, TW12 1AQ",
  #    "latitude"=>51.4303819,
  #    "longitude"=>-0.3745976,
  #    "local_custodian_code"=>5810}, ETC...
  def results_for_postcode(postcode)
    get_json("#{endpoint}/v1/locations?postcode=#{postcode}")
  end
end
