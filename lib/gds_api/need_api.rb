require_relative 'base'

class GdsApi::NeedApi < GdsApi::Base

  def needs(options = {})
    query = query_string(options)

    get_list!("#{endpoint}/needs#{query}")
  end

  def create_need(need)
    post_json!("#{endpoint}/needs", need)
  end

  def organisations
    get_json!("#{endpoint}/organisations")["organisations"]
  end
end
