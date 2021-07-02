require_relative "base"

class GdsApi::LocalLinksManager < GdsApi::Base
  def local_link(authority_slug, lgsl, lgil)
    url = "#{endpoint}/api/link?authority_slug=#{authority_slug}&lgsl=#{lgsl}&lgil=#{lgil}"
    get_json(url)
  end

  def local_authority(authority_slug)
    url = "#{endpoint}/api/local-authority?authority_slug=#{authority_slug}"
    get_json(url)
  end

  def local_link_by_gss(gss, lgsl, lgil)
    url = "#{endpoint}/api/link?gss=#{gss}&lgsl=#{lgsl}&lgil=#{lgil}"
    get_json(url)
  end

  def local_authority_by_gss(gss)
    url = "#{endpoint}/api/local-authority?gss=#{gss}"
    get_json(url)
  end
end
