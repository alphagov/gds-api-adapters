require "gds_api/base"
require "rack/utils"

module GdsApi
  # @api documented
  class Search < Base
    # @api documented
    class V1 < SimpleDelegator
      def add_document(type, id, document)
        post_json(
          documents_url,
          document.merge(
            _type: type,
            _id: id,
          ),
        )
      end

      def delete_document(type, id)
        delete_json(
          "#{documents_url}/#{id}",
          nil,
          _type: type,
        )
      end
    end

    # @api documented
    class V2 < SimpleDelegator
      class InvalidIndex < StandardError; end

      def add_document(id, document, index_name)
        raise(InvalidIndex, index_name) unless index_name == "metasearch"

        post_json(
          "#{base_url}/v2/metasearch/documents",
          document.merge(
            _id: id,
          ),
        )
      end

      def delete_document(id, index_name)
        raise(InvalidIndex, index_name) unless index_name == "metasearch"

        delete_json("#{base_url}/v2/metasearch/documents/#{id}")
      end
    end

    DEFAULT_API_VERSION = "V1".freeze
    API_VERSIONS = {
      "V1" => GdsApi::Search::V1,
      "V2" => GdsApi::Search::V2,
    }.freeze
    class UnknownAPIVersion < StandardError; end

    def initialize(endpoint_url, options = {})
      super
      # The API version provides a simple wrapper around this base class so that we
      # can still access the shared methods present in this class.
      version = options.fetch(:api_version, DEFAULT_API_VERSION)
      api_class = API_VERSIONS[version] || raise(UnknownAPIVersion)
      @api = api_class.new(self)
    end

    # Perform a search.
    #
    # @param args [Hash] A valid search query. See search-api documentation for options.
    #
    # @see https://github.com/alphagov/search-api/blob/master/doc/search-api.md
    def search(args, additional_headers = {})
      request_url = "#{base_url}/search.json?#{Rack::Utils.build_nested_query(args)}"
      get_json(request_url, additional_headers)
    end

    # Perform a batch search.
    #
    # @param searches [Array] An array valid search queries. Maximum of 6. See search-api documentation for options.
    #
    # # @see https://github.com/alphagov/search-api/blob/master/doc/search-api.md
    def batch_search(searches, additional_headers = {})
      url_friendly_searches = searches.each_with_index.map do |search, index|
        { index => search }
      end
      searches_query = { search: url_friendly_searches }
      request_url = "#{base_url}/batch_search.json?#{Rack::Utils.build_nested_query(searches_query)}"
      get_json(request_url, additional_headers)
    end

    # Perform a search, returning the results as an enumerator.
    #
    # The enumerator abstracts away search-api's pagination and fetches new pages when
    # necessary.
    #
    # @param args [Hash] A valid search query. See search-api documentation for options.
    # @param page_size [Integer] Number of results in each page.
    #
    # @see https://github.com/alphagov/search-api/blob/master/doc/search-api.md
    def search_enum(args, page_size: 100, additional_headers: {})
      Enumerator.new do |yielder|
        (0..Float::INFINITY).step(page_size).each do |index|
          search_params = args.merge(start: index.to_i, count: page_size)
          results = search(search_params, additional_headers).to_h.fetch("results", [])
          results.each do |result|
            yielder << result
          end
          if results.count < page_size
            break
          end
        end
      end
    end

    # Add a document to the search index.
    #
    # @param type [String] The search-api document type.
    # @param id [String] The search-api/elasticsearch id. Typically the same as the `link` field, but this is not strictly enforced.
    # @param document [Hash] The document to add. Must match the search-api schema matching the `type` parameter and contain a `link` field.
    # @param index_name (V2 only) Name of the index to be deleted from on
    #   GOV.UK - we only allow deletion from metasearch
    # @return [GdsApi::Response] A status code of 202 indicates the document has been successfully queued.
    #
    # @see https://github.com/alphagov/search-api/blob/master/doc/documents.md
    def add_document(*args)
      @api.add_document(*args)
    end

    # Delete a content-document from the index by base path.
    #
    # Content documents are pages on GOV.UK that have a base path and are
    # returned in searches. This excludes best bets, recommended-links,
    # and contacts, which may be deleted with `delete_document`.
    #
    # @param base_path Base path of the page on GOV.UK.
    # @see https://github.com/alphagov/search-api/blob/master/doc/content-api.md
    def delete_content(base_path)
      request_url = "#{base_url}/content?link=#{base_path}"
      delete_json(request_url)
    end

    # Retrieve a content-document from the index.
    #
    # Content documents are pages on GOV.UK that have a base path and are
    # returned in searches. This excludes best bets, recommended-links,
    # and contacts.
    #
    # @param base_path [String] Base path of the page on GOV.UK.
    # @see https://github.com/alphagov/search-api/blob/master/doc/content-api.md
    def get_content(base_path)
      request_url = "#{base_url}/content?link=#{base_path}"
      get_json(request_url)
    end

    # Delete a non-content document from the search index.
    #
    # For example, best bets, recommended links, or contacts.
    #
    # @param type [String] The search-api document type.
    # @param id [String] The search-api/elasticsearch id. Typically the same as the `link` field.
    # @param index_name (V2 only) Name of the index to be deleted from on
    #   GOV.UK - we only allow deletion from metasearch
    def delete_document(*args)
      @api.delete_document(*args)
    end

    def base_url
      endpoint
    end

    def documents_url
      "#{base_url}/documents"
    end
  end
end
