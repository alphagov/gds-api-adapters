require_relative "base"

class GdsApi::LicenceApplication < GdsApi::Base
  def all_licences
    get_json!("#{@endpoint}/apply-for-a-licence/api/licences")
  end

  def details_for_licence(id, snac_code = nil)
    return nil if id.nil?
    get_json(build_licence_url(id, snac_code))
  end

  def adapter_name
    "licensify"
  end

  private

  def build_licence_url(id, snac_code)
    if snac_code
      "#{@endpoint}/apply-for-a-licence/api/licence/#{id}/#{snac_code}"
    else
      "#{@endpoint}/apply-for-a-licence/api/licence/#{id}"
    end
  end
end
