require_relative 'base'
require_relative 'exceptions'

class GdsApi::ContentApi < GdsApi::Base
  include GdsApi::ExceptionHandling

  def sections
    get_json!("#{base_url}/tags.json?type=section")
  end

  def with_tag(tag)
    get_json!("#{base_url}/with_tag.json?tag=#{tag}&include_children=1")
  end

  private
    def base_url
      endpoint
    end
end
