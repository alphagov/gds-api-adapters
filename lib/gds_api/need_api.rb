require_relative 'base'

class GdsApi::NeedApi < GdsApi::Base

  def needs
    get_list!("#{endpoint}/needs")
  end

  def create_need(need)
    post_json!("#{endpoint}/needs", need)
  end

  def organisations
    get_json!("#{endpoint}/organisations")["organisations"]
  end
end
