require_relative 'base'

class GdsApi::Needotron < GdsApi::Base
  def need_by_id(id, opts = {})
    response = get_json("#{base_url}/#{id}.json")
    return nil if response.nil? or response['need'].nil?

    if opts[:as_hash]
      response.to_hash
    else
      response.to_ostruct.need
    end
  end

private
  def base_url
    "#{@endpoint}/needs"
  end
end
