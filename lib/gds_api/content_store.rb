require "plek"

require_relative "base"
require_relative "exceptions"

class GdsApi::ContentStore < GdsApi::Base
  class ItemNotFound < GdsApi::HTTPNotFound
    def self.build_from(http_error)
      new(http_error.code, http_error.message, http_error.error_details)
    end
  end

  def content_item(base_path)
    get_json(content_item_url(base_path))
  rescue GdsApi::HTTPNotFound => e
    raise ItemNotFound.build_from(e)
  end

  # Returns an array tuple of destination url with status code e.g
  # ["https://www.gov.uk/destination", 301]
  def self.redirect_for_path(content_item, request_path, request_query = "")
    RedirectResolver.call(content_item, request_path, request_query)
  end

private

  def content_item_url(base_path)
    "#{endpoint}/content#{base_path}"
  end

  class RedirectResolver
    def initialize(content_item, request_path, request_query = "")
      @content_item = content_item
      @request_path = request_path
      @request_query = request_query.to_s
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      redirect = redirect_for_path(request_path)
      raise UnresolvedRedirect, "Could not find a matching redirect" unless redirect

      destination_uri = URI.parse(
        resolve_destination(redirect, request_path, request_query),
      )

      url = if destination_uri.absolute?
              destination_uri.to_s
            else
              "#{Plek.new.website_root}#{destination_uri}"
            end

      [url, 301]
    end

    private_class_method :new

  private

    attr_reader :content_item, :request_path, :request_query

    def redirect_for_path(path)
      redirects_by_segments.find do |r|
        next true if r["path"] == path

        route_prefix_match?(r["path"], path) if r["type"] == "prefix"
      end
    end

    def redirects_by_segments
      redirects = content_item["redirects"] || []
      redirects.sort_by { |r| r["path"].split("/").count * -1 }
    end

    def route_prefix_match?(prefix_path, path_to_match)
      prefix_regex = %r{^#{Regexp.escape(prefix_path)}/}
      path_to_match.match prefix_regex
    end

    def resolve_destination(redirect, path, query)
      return redirect["destination"] unless redirect["segments_mode"] == "preserve"

      if redirect["type"] == "prefix"
        prefix_destination(redirect, path, query)
      else
        redirect["destination"] + (query.empty? ? "" : "?#{query}")
      end
    end

    def prefix_destination(redirect, path, query)
      uri = URI.parse(redirect["destination"])
      start_char = redirect["path"].length
      suffix = path[start_char..]

      if uri.path == "" && suffix[0] != "/"
        uri.path = "/#{suffix}"
      else
        uri.path += suffix
      end

      uri.query = query if uri.query.nil? && !query.empty?

      uri.to_s
    end
  end

  class UnresolvedRedirect < GdsApi::BaseError; end
end
