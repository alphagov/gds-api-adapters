require_relative "base"

class GdsApi::LicenceApplication < GdsApi::Base
  def all_licences
    get_json("#{@endpoint}/api/licences")
  end

  def details_for_licence(id, snac_code = nil)
    return nil if id.nil?

    get_json(build_licence_url(id, snac_code))
  end

private

  def build_licence_url(id, snac_code)
    if snac_code
      "#{@endpoint}/api/licence/#{id}/#{snac_code}"
    else
      "#{@endpoint}/api/licence/#{id}"
    end
  end
end
