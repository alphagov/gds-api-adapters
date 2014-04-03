require_relative 'base'
require_relative 'finder_schema'

module GdsApi
  class FinderApi < Base
    def initialize(url, options, &block)
      @schema_factory = options.fetch(:schema_factory) { Schema.method(:new) }
      super(url, options, &block)
    end

    def get_documents(finder_slug, options = {})
      get_json(documents_url(finder_slug, options))
    end

    def get_schema(finder_slug, options = {})
      @schema_factory.call(
        get_json(finder_url(finder_slug, 'schema', options)).to_hash
      )
    end

  private
    def documents_url(finder_slug, options = {})
      finder_url(finder_slug, 'documents', options)
    end

    def finder_url(finder_slug, action, options = {})
      "#{endpoint}/finders/#{CGI.escape(finder_slug)}/#{action}.json#{query_string(options)}"
    end
  end
end
