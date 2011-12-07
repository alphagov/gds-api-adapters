require_relative 'base'

class GdsApi::Needotron < GdsApi::Base
  def need_by_id(id, opts = {})
    need_hash = get_json("#{base_url}/#{id}.json")
    return nil if need_hash.nil? or need_hash['need'].nil?
    
    if opts[:as_hash]
      need_hash
    else
      to_ostruct(need_hash['need']) 
    end
  end
  
private
  def base_url
    "#{@endpoint}/needs"
  end
end
