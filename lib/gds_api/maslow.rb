class GdsApi::Maslow < GdsApi::Base
  def need_page_url(content_id)
    "#{endpoint}/needs/#{content_id}"
  end
end
