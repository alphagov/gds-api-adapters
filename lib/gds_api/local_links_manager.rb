require_relative 'base'

class GdsApi::LocalLinksManager < GdsApi::Base
  def local_link(authority_slug, lgsl, lgil=nil)
    url = "#{endpoint}/api/link?authority_slug=#{authority_slug}&lgsl=#{lgsl}"
    url += "&lgil=#{lgil}" if lgil
    get_json(url)
  end
end
