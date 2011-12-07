require_relative 'base'

class GdsApi::Panopticon < GdsApi::Base

  def artefact_for_slug(slug, opts = {})
    return nil if slug.nil? or slug == ''
    
    details = get_json(url_for_slug(slug))
    if opts[:as_hash]
      details
    else
      to_ostruct(details) 
    end
  end

private
  def base_url
    "#{endpoint}/artefacts"
  end
end
