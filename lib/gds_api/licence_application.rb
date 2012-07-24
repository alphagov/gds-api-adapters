require_relative "base"

class GdsApi::LicenceApplication < GdsApi::Base
  def details_for_licence(id, snac_code = nil)
    return nil if id.nil?

    if response = get_json(build_url(id, snac_code))
      response.to_hash
    else
      nil
    end
  end

  private

  def build_url(id, snac_code)
    if snac_code
      "#{@endpoint}/api/#{id}/#{snac_code}"
    else
      "#{@endpoint}/api/#{id}"
    end
  end
end
