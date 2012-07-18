require_relative 'base'
require_relative 'part_methods'

class GdsApi::Publisher < GdsApi::Base

  def publication_for_slug(slug, options = {})
    return nil if slug.nil? or slug == ''

    response = get_json(url_for_slug(slug, options))
    if response
      container = response.to_ostruct
      container.extend(GdsApi::PartMethods) if container.parts
      convert_updated_date(container)
      container
    else
      nil
    end
  end

  def council_for_slug(slug, snac_codes)
    if json = post_json("#{@endpoint}/local_transactions/#{slug}/verify_snac.json", {'snac_codes' => snac_codes})
      json['snac']
    else
      nil
    end
  end

  def council_for_snac_code(snac)
    if json = get_json("#{@endpoint}/local_transactions/find_by_snac?snac=#{snac}")
      json.to_hash
    else
      nil
    end
  end

  def council_for_name(name)
    name = URI.escape(name)
    if json = get_json("#{@endpoint}/local_transactions/find_by_council_name?name=#{name}")
      json.to_hash
    else
      nil
    end
  end

  def licences_for_ids(ids)
    response = get_json("#{@endpoint}/licences.json?ids=#{ids.map(&:to_s).sort.join(',')}")
    if response
      response.to_ostruct
    else
      nil
    end
  end

private
  def convert_updated_date(container)
    if container.updated_at && container.updated_at.class == String
      container.updated_at = Time.parse(container.updated_at)
    end
  end

  def base_url
    "#{@endpoint}/publications"
  end
end
