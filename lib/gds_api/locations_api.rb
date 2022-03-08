require_relative "base"
require_relative "exceptions"

class GdsApi::LocationsApi < GdsApi::Base
  # Get a list of local custodian codes for a postcode
  #
  # @param [String, nil] postcode The postcode for which the custodian codes are requested
  #
  # @return [Array] All local custodian codes for a specific postcode
  def local_custodian_code_for_postcode(postcode)
    response = get_json("#{endpoint}/locations?postcode=#{postcode}.json")

    return [] if response["results"].nil?

    response["results"].map { |r| r["local_custodian_code"] }.uniq
  end

  # Get the average coordinates for a postcode
  #
  # @param [String, nil] postcode The postcode for which the coordinates are requested
  #
  # @return [Hash] The average coordinates (two fields, "latitude" and "longitude") for a specific postcode
  def coordinates_for_postcode(postcode)
    response = get_json("#{endpoint}/locations?postcode=#{postcode}.json")

    { "latitude" => response["average_latitude"], "longitude" => response["average_longitude"] } unless response["results"].nil?
  end
end
