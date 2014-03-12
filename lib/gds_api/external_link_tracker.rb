require_relative 'base'

class GdsApi::ExternalLinkTracker < GdsApi::Base
  def add_external_link(url)
    put_json!("#{endpoint}/url?url=#{CGI.escape(url)}", {})
  end
end
