require 'json'
require 'net/http'
require 'ostruct'
require_relative 'core-ext/openstruct'
require_relative 'version'
require_relative 'exceptions'

module GdsApi::JsonUtils
  USER_AGENT = "GDS Api Client v. #{GdsApi::VERSION}"
  TIMEOUT_IN_SECONDS = 0.5

  def do_request(url, &block)
    url = URI.parse(url)
    request = url.path
    request = request + "?" + url.query if url.query

    response = Net::HTTP.start(url.host, url.port) do |http|
      http.read_timeout = TIMEOUT_IN_SECONDS
      yield http, request
    end

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      nil
    end
  rescue Errno::ECONNREFUSED
    raise GdsApi::EndpointNotFound.new("Could not connect to #{url}")
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
