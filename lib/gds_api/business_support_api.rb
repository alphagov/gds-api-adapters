require_relative 'base'
require_relative 'exceptions'
require_relative 'list_response'

class GdsApi::BusinessSupportApi < GdsApi::Base

  def schemes(options = {})
    get_list!(url_for_slug('business-support-schemes', options))
  end

  def scheme(slug)
    get_json!(url_for_slug("business-support-schemes/#{slug}"))
  end

  private

  def base_url
    endpoint
  end
end
