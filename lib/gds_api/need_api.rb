require_relative 'base'

class GdsApi::NeedApi < GdsApi::Base

  def needs(options = {})
    query = query_string(options)

    get_list!("#{endpoint}/needs#{query}")
  end

  def need(need_id)
    get_json("#{endpoint}/needs/#{CGI.escape(need_id.to_s)}")
  end

  def create_need(need)
    post_json!("#{endpoint}/needs", need)
  end

  def update_need(need_id, need_update)
    # `need_update` can be a hash of updated fields or a complete need
    put_json!("#{endpoint}/needs/#{CGI.escape(need_id.to_s)}", need_update)
  end

  def organisations
    get_json!("#{endpoint}/organisations")["organisations"]
  end
end
