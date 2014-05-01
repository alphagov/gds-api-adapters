class GdsApi::Maslow < GdsApi::Base
  def need_page_url(need_id)
    "#{endpoint}/needs/#{need_id}"
  end
end
