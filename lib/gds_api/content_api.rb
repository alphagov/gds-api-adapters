require_relative 'base'
require_relative 'exceptions'
require_relative 'list_response'

class GdsApi::ContentApi < GdsApi::Base
  def initialize(endpoint_url, options = {})
    # If the `web_urls_relative_to` option is given, the adapter will convert
    # any `web_url` values to relative URLs if they are from the same host.
    #
    # For example: "https://www.gov.uk"

    @web_urls_relative_to = options.delete(:web_urls_relative_to)
    super
  end

  def sections
    tags("section")
  end

  def root_sections
    root_tags("section")
  end

  def sub_sections(parent_tag)
    child_tags("section", parent_tag)
  end

  def tags(tag_type, options = {})
    params = [
      "type=#{CGI.escape(tag_type)}"
    ]
    params << "sort=#{options[:sort]}" if options.has_key?(:sort)
    params << "draft=true" if options[:draft]
    params << "cachebust=#{Time.now.utc.to_i}#{rand(1000)}" if options[:bust_cache]

    get_list("#{base_url}/tags.json?#{params.join('&')}")
  end

  def root_tags(tag_type)
    get_list("#{base_url}/tags.json?type=#{CGI.escape(tag_type)}&root_sections=true")
  end

  def child_tags(tag_type, parent_tag, options = {})
    params = [
      "type=#{CGI.escape(tag_type)}",
      "parent_id=#{CGI.escape(parent_tag)}",
    ]
    params << "sort=#{options[:sort]}" if options.has_key?(:sort)

    get_list("#{base_url}/tags.json?#{params.join('&')}")
  end

  def tag(tag, tag_type = nil)
    if tag_type.nil?
      raise "Requests for tags without a tag_type are no longer supported. You probably want a tag_type of 'section'. See https://github.com/alphagov/govuk_content_api/blob/f4c0102a1ae4970be6a440707b89798442f768b9/govuk_content_api.rb#L241-L250"
    end

    url = [base_url, "tags", CGI.escape(tag_type), CGI.escape(tag)].join("/") + ".json"
    get_json(url)
  end

  def for_need(need_id)
    get_list("#{base_url}/for_need/#{CGI.escape(need_id.to_s)}.json")
  end

  def artefact(slug, params = {})
    get_json(artefact_url(slug, params))
  end

  def artefact!(slug, params = {})
    get_json(artefact_url(slug, params))
  end

  def artefacts
    get_list("#{base_url}/artefacts.json")
  end

  def local_authority(snac_code)
    get_json("#{base_url}/local_authorities/#{CGI.escape(snac_code)}.json")
  end

  def local_authorities_by_name(name)
    get_json("#{base_url}/local_authorities.json?name=#{CGI.escape(name)}")
  end

  def local_authorities_by_snac_code(snac_code)
    get_json("#{base_url}/local_authorities.json?snac_code=#{CGI.escape(snac_code)}")
  end

  def licences_for_ids(ids)
    ids = ids.map(&:to_s).sort.join(',')
    get_json("#{@endpoint}/licences.json?ids=#{ids}")
  end

  def get_list(url)
    get_json(url) { |r|
      GdsApi::ListResponse.new(r, self, web_urls_relative_to: @web_urls_relative_to)
    }
  end

  def get_json(url, &create_response)
    create_response = create_response || Proc.new { |r|
      GdsApi::Response.new(r, web_urls_relative_to: @web_urls_relative_to)
    }
    super(url, &create_response)
  end

private

  def base_url
    endpoint
  end

  def key_for_tag_type(tag_type)
    tag_type.nil? ? "tag" : CGI.escape(tag_type)
  end

  def artefact_url(slug, params)
    url = "#{base_url}/#{CGI.escape(slug)}.json"
    query = params.map { |k, v| "#{k}=#{v}" }
    if query.any?
      url += "?#{query.join('&')}"
    end

    if params[:edition] && ! options.include?(:bearer_token)
      raise GdsApi::NoBearerToken
    end
    url
  end
end
