require_relative 'base'

class GdsApi::NeedApi < GdsApi::Base

  def needs(options = {})
    query = query_string(options)

    get_list!("#{endpoint}/needs#{query}")
  end

  def content_id(need_id)
    get_raw("#{endpoint}/needs/#{CGI.escape(need_id.to_s)}/content_id")
  end

  def needs_by_id(*ids)
    ids_string = ids.flatten.map(&:to_i).sort.join(',')
    query = query_string(ids: ids_string)

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

  def close(need_id, duplicate_of)
    # duplicate_of is a hash of the required fields for closing
    # a need as a duplicate: { "duplicate_of" => 100001,
    #                          "author" => { ... }
    #                        }
    put_json!("#{endpoint}/needs/#{CGI.escape(need_id.to_s)}/closed", duplicate_of)
  end

  def reopen(need_id, author)
    # author params: { "author" => { ... } }"
    # NB: This should really be a POST
    delete_json_with_params!("#{endpoint}/needs/#{CGI.escape(need_id.to_s)}/closed", author)
  end

  def create_note(note)
    post_json!("#{endpoint}/notes", note)
  end
end
