require_relative "base"

class GdsApi::Support < GdsApi::Base
  def feedback_url(slug)
    "#{base_url}/anonymous_feedback?path=#{slug}"
  end

private

  def base_url
    endpoint
  end
end
