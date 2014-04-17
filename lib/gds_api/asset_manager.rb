require_relative 'base'
require_relative 'exceptions'

class GdsApi::AssetManager < GdsApi::Base
  include GdsApi::ExceptionHandling

  # Creates an asset given attributes
  #
  # Makes a `POST` request to the asset manager api to create an asset. The api accepts
  #   the following attributes:
  #
  # * `file` - a File object
  #
  # @param asset [Hash] The attributes for the asset to send to the api.
  # @return [Net::HTTPResponse] The raw http response from the api.
  #
  # @raise [HTTPErrorResponse] if the request returns an error
  def create_asset(asset)
    post_multipart("#{base_url}/assets", { :asset => asset })
  end

  # Updates an asset given attributes
  #
  # Makes a `PUT` request to the asset manager api to update an asset.
  # The api accepts the following attributes:
  #
  # * `file` - a File object
  #
  # @param id [String] The asset identifier
  # @param asset [Hash] The attributes for the asset to send to the api.
  # @return [Net::HTTPResponse] The raw http response from the api.
  #
  # @raise [HTTPErrorResponse] if the request returns an error
  def update_asset(id, asset)
    put_multipart("#{base_url}/assets/#{id}", { :asset => asset })
  end

  # Fetches an asset given the id
  #
  # @param id [String] The asset identifier
  # @return [Response, nil] A response object containing the parsed JSON response. If
  #   the asset cannot be found, nil wil be returned.
  #
  # @raise [HTTPErrorResponse] if the request returns an error
  def asset(id)
    get_json("#{base_url}/assets/#{id}")
  end

  private
    def base_url
      endpoint
    end
end
