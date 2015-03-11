require_relative 'base'
require_relative 'exceptions'

class GdsApi::ContentRegister < GdsApi::Base

  def put_entry(content_id, entry)
    put_json!(entry_url(content_id), entry)
  end

  def entries(format)
    get_json!(entries_url(format))
  end

private

  def entries_url(format)
    "#{endpoint}/entries?format=#{format}"
  end

  def entry_url(content_id)
    "#{endpoint}/entry/#{content_id}"
  end
end
