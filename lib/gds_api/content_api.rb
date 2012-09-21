require_relative 'base'
require_relative 'exceptions'

class GdsApi::ContentApi < GdsApi::Base
  include GdsApi::ExceptionHandling

  def sections
    get_json!("#{base_url}/tags.json?type=section")
  end

  def tag(tag)
    get_json!("#{base_url}/tags/#{CGI.escape(tag)}.json")
  end

  def with_tag(tag)
    get_json!("#{base_url}/with_tag.json?tag=#{CGI.escape(tag)}&include_children=1")
  end

  def curated_list(tag)
    get_json("#{base_url}/with_tag.json?tag=#{CGI.escape(tag)}&sort=curated")
  end

  def artefact(slug)
    get_json("#{base_url}/#{CGI.escape(slug)}.json")
  end

  def artefact_with_snac_code(slug, snac)
    get_json("#{base_url}/#{CGI.escape(slug)}.json?snac=#{CGI.escape(snac)}")
  end

  def local_authority(snac_code)
    get_json("#{base_url}/local_authorities/#{CGI.escape(snac_code)}.json")
  end

  def local_authorities_by_name(name)
    get_json!("#{base_url}/local_authorities.json?name=#{CGI.escape(name)}")
  end

  def local_authorities_by_snac_code(snac_code)
    get_json!("#{base_url}/local_authorities.json?snac_code=#{CGI.escape(snac_code)}")
  end

  private
    def base_url
      endpoint
    end
end
