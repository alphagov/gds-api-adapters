require_relative 'base'
require_relative 'panopticon/registerer'
require_relative 'exceptions'

class GdsApi::Panopticon < GdsApi::Base

  include GdsApi::ExceptionHandling

  def all
    url = base_url + '.json'
    json = get_json url
    to_ostruct json
  end

  def artefact_for_slug(slug, opts = {})
    return nil if slug.nil? or slug == ''
    get_json(url_for_slug(slug))
  end

  def create_artefact(artefact)
    ignoring GdsApi::HTTPErrorResponse do
      create_artefact! artefact
    end
  end

  def create_artefact!(artefact)
    post_json!(base_url + ".json", artefact)
  end

  def put_artefact(id_or_slug, artefact)
    ignoring GdsApi::HTTPErrorResponse do
      put_artefact! id_or_slug, artefact
    end
  end

  def put_artefact!(id_or_slug, artefact)
    put_json!("#{base_url}/#{id_or_slug}.json", artefact)
  end

  def update_artefact(id_or_slug, artefact)
    self.class.logger.warn(
      "The update_artefact method is deprecated and may be removed in a " +
      "future release. You should use put_artefact instead."
    )
    put_artefact(id_or_slug, artefact)
  end

  def delete_artefact!(id_or_slug)
    delete_json!("#{base_url}/#{id_or_slug}.json")
  end

private
  def base_url
    "#{endpoint}/artefacts"
  end
end
