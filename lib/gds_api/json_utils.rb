require 'json'
require 'net/http'
require 'ostruct'
require_relative 'core-ext/openstruct'
require_relative 'version'
require_relative 'exceptions'

module GdsApi::JsonUtils
  REQUEST_HEADERS = {
    'Accept' => 'application/json', 
    'Content-Type' => 'application/json',
    'User-Agent' => "GDS Api Client v. #{GdsApi::VERSION}"
  }
  TIMEOUT_IN_SECONDS = 0.5

  def do_request(url, &block)
    loggable = {request_uri: url, start_time: Time.now.to_f}

    url = URI.parse(url)
    request = url.path
    request = request + "?" + url.query if url.query

    response = Net::HTTP.start(url.host, url.port) do |http|
      http.read_timeout = TIMEOUT_IN_SECONDS
      yield http, request
    end

    if response.is_a?(Net::HTTPSuccess)
      GdsApi::Base.logger.info loggable.merge(status: 'success', end_time: Time.now).to_json
      JSON.parse(response.body)
    else
      loggable.merge!(status: '404', end_time: Time.now.to_f)
      GdsApi::Base.logger.info loggable.to_json
      nil
    end
  rescue Errno::ECONNREFUSED
    GdsApi::Base.logger.info loggable.merge(status: 'refused', end_time: Time.now.to_f).to_json
    raise GdsApi::EndpointNotFound.new("Could not connect to #{url}")
  rescue Timeout::Error, Errno::ECONNRESET
    GdsApi::Base.logger.info loggable.merge(status: 'failed', end_time: Time.now.to_f).to_json
    nil
  end

  def get_json(url)
    do_request(url) do |http, path|
      http.get(path, REQUEST_HEADERS)
    end
  end

  def post_json(url, params)
    do_request(url) do |http, path|
      http.post(path, params.to_json, REQUEST_HEADERS)
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
