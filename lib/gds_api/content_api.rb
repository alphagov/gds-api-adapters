require_relative 'base'
require_relative 'exceptions'

class GdsApi::ContentApi < GdsApi::Base
  include GdsApi::ExceptionHandling

  def sections
    get_json!("#{base_url}/tags.json?type=section")
  end

  def root_sections
    get_json!("#{base_url}/tags.json?type=section&root_sections=true")
  end

  def sub_sections(parent_tag)
    get_json!("#{base_url}/tags.json?type=section&parent_id=#{CGI.escape(parent_tag)}")
  end

  def tag(tag)
    get_json("#{base_url}/tags/#{CGI.escape(tag)}.json")
  end

  def with_tag(tag)
    get_json!("#{base_url}/with_tag.json?tag=#{CGI.escape(tag)}&include_children=1")
  end

  def curated_list(tag)
    get_json("#{base_url}/with_tag.json?tag=#{CGI.escape(tag)}&sort=curated")
  end

  def sorted_by(tag, sort_by)
    get_json!("#{base_url}/with_tag.json?tag=#{CGI.escape(tag)}&sort=#{sort_by}")
  end

  def artefact(slug, params={})
    edition = params[:edition]
    snac = params[:snac]

    url = "#{base_url}/#{slug}.json"
    query = params.map { |k,v| "#{k}=#{v}" }
    if query.any?
      url += "?#{query.join("&")}"
    end

    if edition && ! options.include?(:bearer_token)
      raise GdsApi::NoBearerToken
    end
    get_json(url)
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

  def business_support_schemes(identifiers)
    identifiers = identifiers.map {|i| CGI.escape(i) }
    url_template = "#{base_url}/business_support_schemes.json?identifiers="
    response = nil # assignment necessary for variable scoping

    start_url = "#{url_template}#{identifiers.shift}"
    last_batch_url = identifiers.inject(start_url) do |url, id|
      new_url = [url, id].join(',')
      if new_url.length >= 2000
        # fetch a batch using the previous url, then return a new start URL with this id
        response = get_batch(url, response)
        "#{url_template}#{id}"
      else
        new_url
      end
    end
    get_batch(last_batch_url, response)
  end

  private
    def base_url
      endpoint
    end

    def get_batch(batch_url, existing_response = nil)
      batch_response = get_json!(batch_url)
      if existing_response
        existing_response.to_hash["total"] += batch_response["total"]
        existing_response.to_hash["results"] += batch_response["results"]
        existing_response
      else
        batch_response
      end
    end
end
