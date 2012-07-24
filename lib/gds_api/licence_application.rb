require_relative "base"

class GdsApi::LicenceApplication < GdsApi::Base
  def details_for_licence(id, snac_code = nil)
    return nil if id.nil?

    if response = get_raw(build_url(id, snac_code))
      begin
        JSON.parse(response)
      rescue JSON::ParserError => e
        nil
      end
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
