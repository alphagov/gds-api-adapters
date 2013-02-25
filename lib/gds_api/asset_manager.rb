require_relative 'base'
require_relative 'exceptions'

class GdsApi::AssetManager < GdsApi::Base
  include GdsApi::ExceptionHandling

  def create_asset(asset)
    post_multipart("#{base_url}/assets", { :asset => asset })
  end

  private
    def base_url
      endpoint
    end
end
