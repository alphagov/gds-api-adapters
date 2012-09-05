require_relative 'response'
require_relative 'exceptions'

# TODO: This is a work in progress
module GdsApi
  class OAuth2Client
    def initialize(options)
      raise "access_token required" unless options[:access_token]
      @oauth_client = OAuth2::Client.new(nil, nil)
      @access_token = OAuth2::AccessToken.new(@oauth_client, options[:access_token], options[:token_options])
    end

    def get_json(url)
      @access_token.get(url, headers: REQUEST_HEADERS)
    end

    def post_json(url, params)
      @access_token.post(url, body: params, headers: REQUEST_HEADERS)
    end

    def put_json(url, params)
      @access_token.put(url, body: params, headers: REQUEST_HEADERS)
    end
  end
end