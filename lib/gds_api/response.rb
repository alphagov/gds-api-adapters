require 'json'
require 'ostruct'
require_relative 'core-ext/openstruct'

module GdsApi

  # This wraps an HTTP response with a JSON body, and presents this as
  # an object that has the read behaviour of both a Hash and an OpenStruct
  class Response
    extend Forwardable
    include Enumerable

    def_delegators :to_hash, :[], :"<=>", :each

    def initialize(http_response)
      @http_response = http_response
    end

    def raw_response_body
      @http_response.body
    end

    def code
      # Return an integer code for consistency with HTTPErrorResponse
      @http_response.code
    end

    def to_hash
      @parsed ||= JSON.parse(@http_response.body)
    end

    def to_ostruct
      @ostruct ||= self.class.build_ostruct_recursively(to_hash)
    end

    def method_missing(method)
      to_ostruct.send(method)
    end

    def respond_to_missing?(method, include_private)
      to_ostruct.respond_to?(method, include_private)
    end

    def present?; true; end
    def blank?; false; end

    def self.build_ostruct_recursively(value)
      case value
      when Hash
        OpenStruct.new(Hash[value.map { |k, v| [k, build_ostruct_recursively(v)] }])
      when Array
        value.map { |v| build_ostruct_recursively(v) }
      else
        value
      end
    end
  end
end
