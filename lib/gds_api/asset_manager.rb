require_relative 'base'
require_relative 'exceptions'

class GdsApi::AssetManager < GdsApi::Base

  # Creates an asset given a hash with one +file+ attribute
  #
  # Makes a +POST+ request to the asset manager api to create an asset.
  #
  # The asset must be provided as a +Hash+ with a single +file+ attribute that
  # behaves like a +File+ object. The +content-type+ that the asset manager will
  # subsequently serve will be based *only* on the file's extension (derived
  # from +#path+). If you supply a +content-type+ via, for example
  # +ActionDispatch::Http::UploadedFile+ or another multipart wrapper, it will
  # be ignored.
  #
  # @param asset [Hash] The attributes for the asset to send to the api. Must
  #   contain +file+, which behaves like a +File+. All other attributes will be
  #   ignored.
  # @return [GdsApi::Response] The wrapped http response from the api. Behaves
  #   both as a +Hash+ and an +OpenStruct+, and responds to the following:
  #     :id           the URL of the asset
  #     :name         the filename of the asset that will be served
  #     :content_type the content_type of the asset
  #     :file_url     the URL from which the asset will be served when it has
  #                   passed a virus scan
  #     :state        One of 'unscanned', 'clean', or 'infected'. Unless the state is
  #                   'clean' the asset at the :file_url will 404
  #
  # @raise [HTTPErrorResponse] if the request returns an error
  #
  # @example Upload a file from disk
  #   response = asset_manager.create_asset(file: File.new('image.jpg', 'r'))
  #   response['id']           #=> "http://asset-manager.dev.gov.uk/assets/576bbc52759b74196b000012"
  #   response['content_type'] #=> "image/jpeg"
  # @example Upload a file from a Rails param, (typically a multipart wrapper)
  #    params[:file] #=> #<ActionDispatch::Http::UploadedFile:0x007fc60b43c5c8
  #                      # @content_type="application/foofle",
  #                      # @original_filename="cma_case_image.jpg",
  #                      # @tempfile="spec/support/images/cma_case_image.jpg">
  #
  #    # Though we sent a file with a +content_type+ of 'application/foofle',
  #    # this was ignored
  #    response = asset_manager.create_asset(file: params[:file])
  #    response['content_type'] #=> "image/jpeg"
  def create_asset(asset)
    post_multipart("#{base_url}/assets", { :asset => asset })
  end

  # Updates an asset given a hash with one +file+ attribute
  #
  # Makes a +PUT+ request to the asset manager api to update an asset.
  #
  # The asset must be provided as a +Hash+ with a single +file+ attribute that
  # behaves like a +File+ object. The +content-type+ that the asset manager will
  # subsequently serve will be based *only* on the file's extension (derived
  # from +#path+). If you supply a +content-type+ via, for example
  # +ActionDispatch::Http::UploadedFile+ or another multipart wrapper, it will
  # be ignored.
  #
  # @param id [String] The asset identifier (a UUID).
  # @param asset [Hash] The attributes for the asset to send to the api. Must
  #   contain +file+, which behaves like a +File+. All other attributes will be
  #   ignored.
  # @return [GdsApi::Response] The wrapped http response from the api. Behaves
  #   both as a +Hash+ and an +OpenStruct+, and responds to the following:
  #     :id           the URL of the asset
  #     :name         the filename of the asset that will be served
  #     :content_type the content_type of the asset
  #     :file_url     the URL from which the asset will be served when it has
  #                   passed a virus scan
  #     :state        One of 'unscanned', 'clean', or 'infected'. Unless the state is
  #                   'clean' the asset at the :file_url will 404
  #
  # @raise [HTTPErrorResponse] if the request returns an error
  # @example Update a file from disk
  #   uuid = '594602dd-75b3-4e6f-b5d1-cacf8c4d4164'
  #   asset_manager.update_asset(uuid, file: File.new('image.jpg', 'r'))
  def update_asset(id, asset)
    put_multipart("#{base_url}/assets/#{id}", { :asset => asset })
  end

  # Fetches an asset given the id
  #
  # @param id [String] The asset identifier (a UUID).
  # @return [GdsApi::Response, nil] A response object containing the parsed JSON response. If
  #   the asset cannot be found, +nil+ wil be returned.
  #
  # @raise [HTTPErrorResponse] if the request returns an error
  def asset(id)
    get_json("#{base_url}/assets/#{id}")
  end

  # Deletes an asset given an id
  #
  # Makes a +DELETE+ request to the asset manager api to delete an asset.
  #
  # @param id [String] The asset identifier (a UUID).
  # @return [GdsApi::Response] The wrapped http response from the api. Behaves
  #   both as a +Hash+ and an +OpenStruct+, and responds to the following:
  #     :id           the URL of the asset
  #     :name         the filename of the asset that will be served
  #     :content_type the content_type of the asset
  #     :file_url     the URL from which the asset will be served when it has
  #                   passed a virus scan
  #     :state        One of 'unscanned', 'clean', or 'infected'. Unless the state is
  #                   'clean' the asset at the :file_url will 404
  #
  # @raise [HTTPErrorResponse] if the request returns an error
  # @example Delete a file from disk
  #   uuid = '594602dd-75b3-4e6f-b5d1-cacf8c4d4164'
  #   asset_manager.delete_asset(uuid)
  def delete_asset(id)
    delete_json("#{base_url}/assets/#{id}")
  end

  # Restores an asset given an id
  #
  # Makes a +POST+ request to the asset manager api to restore an asset.
  #
  # @param id [String] The asset identifier (a UUID).
  # @return [GdsApi::Response] The wrapped http response from the api. Behaves
  #   both as a +Hash+ and an +OpenStruct+, and responds to the following:
  #     :id           the URL of the asset
  #     :name         the filename of the asset that will be served
  #     :content_type the content_type of the asset
  #     :file_url     the URL from which the asset will be served when it has
  #                   passed a virus scan
  #     :state        One of 'unscanned', 'clean', or 'infected'. Unless the state is
  #                   'clean' the asset at the :file_url will 404
  #
  # @raise [HTTPErrorResponse] if the request returns an error
  # @example Restore a deleted file
  #   uuid = '594602dd-75b3-4e6f-b5d1-cacf8c4d4164'
  #   asset_manager.restore_asset(uuid)
  def restore_asset(id)
    post_json("#{base_url}/assets/#{id}/restore")
  end

  private
    def base_url
      endpoint
    end
end
