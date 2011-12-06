require 'json'
require 'net/http'
require 'ostruct'
require_relative 'core-ext/openstruct'
require_relative 'version'

module GdsApi::JsonUtils
  USER_AGENT = "GDS Api Client v. #{GdsApi::VERSION}"

  def get_json(url)
    url = URI.parse(url)
    request = url.path
    request = request + "?" + url.query if url.query

    response = Net::HTTP.start(url.host, url.port) do |http|
      http.get(request, {'Accept' => 'application/json', 'User-Agent' => USER_AGENT})
    end
    if response.code.to_i != 200
      return nil
    else
      return JSON.parse(response.body)
    end
  end

  def post_json(url,params)
    url = URI.parse(url)
    Net::HTTP.start(url.host, url.port) do |http|
      post_response = http.post(url.path, params.to_json, {'Content-Type' => 'application/json', 'User-Agent' => USER_AGENT})
      if post_response.code == '200'
        return JSON.parse(post_response.body)
      end
    end
    return nil
  end

  def to_ostruct(object)
    case object
    when Hash
      OpenStruct.new Hash[object.map { |key, value| [key, to_ostruct(value)] }]
    when Array
      object.map { |k| to_ostruct(k) }
    else
      object
    end
  end
end