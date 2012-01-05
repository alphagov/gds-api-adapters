require_relative 'base'

class GdsApi::Panopticon < GdsApi::Base

  def artefact_for_slug(slug, opts = {})
    return nil if slug.nil? or slug == ''
    get_json(url_for_slug(slug))
  end

  def create_artefact(artefact)
    post_json(base_url + ".json", artefact)
  end

  def update_artefact(id_or_slug, artefact)
    put_json("#{base_url}/#{id_or_slug}.json", artefact)
  end

private
  def base_url
    "#{endpoint}/artefacts"
  end
end
