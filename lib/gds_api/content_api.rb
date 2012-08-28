require_relative 'base'
require_relative 'exceptions'

class GdsApi::ContentApi < GdsApi::Base
  include GdsApi::ExceptionHandling

  def all
    url = base_url + '.json'
    json = get_json(url)
    to_ostruct(json)
  end

  def artefact_for_slug(slug, opts = {})
    return nil if slug.nil? or slug == ''
    get_json(url_for_slug(slug))
  end

private
  def base_url
    "#{endpoint}/artefacts"
  end
end
