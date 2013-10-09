require_relative 'base'

class GdsApi::NeedApi < GdsApi::Base

  def create_need(need)
    post_json!("#{endpoint}/needs", need)
  end

  def organisations
    get_json!("#{endpoint}/organisations")["organisations"]
  end
end
