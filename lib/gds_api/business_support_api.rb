require_relative 'base'
require_relative 'exceptions'
require_relative 'list_response'

class GdsApi::BusinessSupportApi < GdsApi::Base
  include GdsApi::ExceptionHandling

  def schemes(options = {})
    get_list!(url_for_slug('search', options))
  end

  private

  def base_url
    endpoint
  end
end
