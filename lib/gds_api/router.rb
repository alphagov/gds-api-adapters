require_relative 'base'
#require_relative 'exceptions'

class GdsApi::Router < GdsApi::Base

  ### Backends

  def get_backend(id)
    get_json("#{endpoint}/backends/#{CGI.escape(id)}")
  end

  def add_backend(id, url)
    put_json!("#{endpoint}/backends/#{CGI.escape(id)}", :backend => {:backend_url => url})
  end

  def delete_backend(id)
    delete_json!("#{endpoint}/backends/#{CGI.escape(id)}")
  end

  ### Routes

  def get_route(path, type)
    get_json("#{endpoint}/routes?incoming_path=#{CGI.escape(path)}&route_type=#{CGI.escape(type)}")
  end

  def add_route(path, type, backend_id)
    response = put_json!("#{endpoint}/routes", :route => {:incoming_path => path, :route_type => type, :handler => "backend", :backend_id => backend_id})
    commit_routes
    response
  end

  def add_redirect_route(path, type, destination, redirect_type = "permanent")
    response = put_json!("#{endpoint}/routes", :route => {:incoming_path => path, :route_type => type, :handler => "redirect",
              :redirect_to => destination, :redirect_type => redirect_type})
    commit_routes
    response
  end

  def delete_route(path, type)
    response = delete_json!("#{endpoint}/routes?incoming_path=#{CGI.escape(path)}&route_type=#{CGI.escape(type)}")
    commit_routes
    response
  end

  def commit_routes
    post_json!("#{endpoint}/routes/commit", {})
  end
end
