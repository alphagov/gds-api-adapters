require_relative "base"

class GdsApi::Imminence < GdsApi::Base
  def api_url(type, params)
    vals = %i[limit lat lng postcode local_authority_slug].select { |p| params.include? p }
    querystring = URI.encode_www_form(vals.map { |p| [p, params[p]] })
    "#{@endpoint}/places/#{type}.json?#{querystring}"
  end

  def places(type, lat, lon, limit = 5)
    url = api_url(type, lat:, lng: lon, limit:)
    get_json(url)
  end

  def places_for_postcode(type, postcode, limit = 5, local_authority_slug = nil)
    options = { postcode:, limit: }
    options.merge!(local_authority_slug:) if local_authority_slug
    url = api_url(type, options)
    get_json(url) || []
  end

  def places_kml(type)
    get_raw("#{@endpoint}/places/#{type}.kml").body
  end
end
