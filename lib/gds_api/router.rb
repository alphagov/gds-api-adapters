require_relative 'base'

class GdsApi::Router < GdsApi::Base
  ### Backends

  def get_backend(id)
    get_json("#{endpoint}/backends/#{CGI.escape(id)}")
  end

  def add_backend(id, url)
    put_json("#{endpoint}/backends/#{CGI.escape(id)}", backend: { backend_url: url })
  end

  def delete_backend(id)
    delete_json("#{endpoint}/backends/#{CGI.escape(id)}")
  end

  ### Routes

  def get_route(path)
    get_json("#{endpoint}/routes?incoming_path=#{CGI.escape(path)}")
  end

  def add_route(path, type, backend_id, options = {})
    response = put_json("#{endpoint}/routes", route: { incoming_path: path, route_type: type, handler: "backend", backend_id: backend_id })
    commit_routes if options[:commit]
    response
  end

  def add_redirect_route(path, type, destination, redirect_type = "permanent", options = {})
    response = put_json(
      "#{endpoint}/routes",
      route: {
        incoming_path: path,
        route_type: type,
        handler: "redirect",
        redirect_to: destination,
        redirect_type: redirect_type,
        segments_mode: options[:segments_mode]
      }
    )

    commit_routes if options[:commit]
    response
  end

  def add_gone_route(path, type, options = {})
    response = put_json("#{endpoint}/routes", route: { incoming_path: path, route_type: type, handler: "gone" })
    commit_routes if options[:commit]
    response
  end

  def delete_route(path, hard_delete: false, commit: false)
    url = "#{endpoint}/routes?incoming_path=#{CGI.escape(path)}"
    url += "&hard_delete=true" if hard_delete

    response = delete_json(url)
    commit_routes if commit
    response
  end

  def commit_routes
    post_json("#{endpoint}/routes/commit", {})
  end
end
