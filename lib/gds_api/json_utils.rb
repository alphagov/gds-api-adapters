require 'json'
require 'net/http'
require 'ostruct'
require_relative 'core-ext/openstruct'
require_relative 'version'

module GdsApi::JsonUtils
  USER_AGENT = "GDS Api Client v. #{GdsApi::VERSION}"
  TIMEOUT = 500

  def do_request(url, &block)
    url = URI.parse(url)
    request = url.path
    request = request + "?" + url.query if url.query

    response = Net::HTTP.start(url.host, url.port) do |http|
      http.read_timeout = TIMEOUT
      yield http, request
    end

    if response.code.to_i != 200
      return nil
    else
      return JSON.parse(response.body)
    end
  rescue Timeout::Error, Errno::ECONNRESET
    nil
  end

  def get_json(url)
    do_request(url) do |http, path|
      http.get(path, {'Accept' => 'application/json', 'User-Agent' => USER_AGENT})
    end
  end

  def post_json(url, params)
    do_request(url) do |http, path|
      http.post(path, params.to_json, {'Content-Type' => 'application/json', 'User-Agent' => USER_AGENT})
    end
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
