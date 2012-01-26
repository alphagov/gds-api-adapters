require 'json'
require 'ostruct'
require_relative 'core-ext/openstruct'

module GdsApi
  class Response
    extend Forwardable
    include Enumerable

    def_delegators :to_hash, :[], :"<=>", :each

    def initialize(net_http_response)
      @net_http_response = net_http_response
    end

    def to_hash
      @parsed ||= JSON.parse(@net_http_response.body)
    end

    def to_ostruct
      self.class.build_ostruct_recursively(to_hash)
    end

    def method_missing(method)
      if to_hash.has_key?(method.to_s)
        to_ostruct.send(method)
      else
        nil
      end
    end

    def respond_to_missing?(method, include_private)
      to_hash.has_key?(method.to_s)
    end

    def present?; ! blank?; end
    def blank?; false; end

  private

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