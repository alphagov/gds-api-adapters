require_relative 'base'

class GdsApi::Contactotron < GdsApi::Base
  def contact_for_uri(uri)
    to_ostruct get_json(uri)
  end
  
  private
    def json_for_uri(uri)
      open(uri, 'Accept' => Mime::JSON.to_s).read
    rescue OpenURI::HTTPError
      nil
    end
end
