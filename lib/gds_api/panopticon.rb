require_relative 'base'

class GdsApi::Panopticon < GdsApi::Base

  def artefact_for_slug(slug)
    return nil if slug.nil? or slug == ''
    
    to_ostruct get_json(url_for_slug(slug))
  end

  private
    def base_url
      "#{endpoint}/artefacts"
    end
end
