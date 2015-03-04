require_relative 'base'
require_relative 'exceptions'

class GdsApi::ContentRegister < GdsApi::Base

  def entries(format)
    get_json!(entries_url(format))
  end

  private

  def entries_url(format)
    "#{endpoint}/entries?format=#{format}"
  end
end
